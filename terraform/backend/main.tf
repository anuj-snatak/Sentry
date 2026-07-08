# One-time bootstrap for the Terraform remote backend shared by every
# environment (dev/qa/uat/prod). Apply this once per AWS account/region
# with local state, then point terraform/environments/*/backend.tf at the
# outputs below. Re-running this in the normal pipeline is neither needed
# nor safe (it would create a circular backend dependency).

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Component = "state-backend"
  }
}

# KMS key dedicated to encrypting Terraform state at rest. A dedicated key
# (rather than the AWS-managed aws/s3 key) lets us scope key policy access
# to exactly the principals that should ever read state.
resource "aws_kms_key" "state" {
  description             = "${var.project_name} Terraform state encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.project_name}-terraform-state"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
      # Deliberately no "deny unless the request carries an explicit
      # x-amz-server-side-encryption: aws:kms header" statement here.
      # aws_s3_bucket_server_side_encryption_configuration.state above
      # already forces SSE-KMS as the bucket's *default* encryption for
      # every object, with no client cooperation required. A per-request
      # header requirement on top of that doesn't add real protection
      # (an object can't land in this bucket unencrypted either way) but
      # it does actively break any client — including Terraform's own S3
      # backend — that uploads without manually setting that header and
      # just relies on the bucket default, which is the normal way to
      # use S3 default encryption. Found the hard way: every `terraform
      # apply` state write was failing with AccessDenied against this
      # exact statement.
    ]
  })
}

# Created only once trusted_principal_arns is populated: the Jenkins
# controller/agent must already exist (with its own instance role) before
# it has an ARN this role's trust policy can reference.
module "jenkins_deploy_role" {
  count  = length(var.jenkins_trusted_principal_arns) > 0 ? 1 : 0
  source = "../modules/iam/jenkins-deploy-role"

  name                      = "${var.project_name}-jenkins-deploy"
  project_name              = var.project_name
  trusted_principal_arns    = var.jenkins_trusted_principal_arns
  external_id               = var.jenkins_external_id
  permissions_boundary_arn  = var.jenkins_permissions_boundary_arn
  tags                      = local.common_tags
}

resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  tags = local.common_tags
}
