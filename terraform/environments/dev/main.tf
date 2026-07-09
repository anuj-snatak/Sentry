data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Two AZs is the minimum for an ALB + ASG to be meaningfully highly
  # available; dev intentionally stays small while still exercising the
  # exact same multi-AZ code path prod uses.
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }

  public_subnets = {
    a = { cidr_block = cidrsubnet(var.vpc_cidr, 4, 0), az = local.azs[0] }
    b = { cidr_block = cidrsubnet(var.vpc_cidr, 4, 1), az = local.azs[1] }
  }

  private_subnets = {
    a = { cidr_block = cidrsubnet(var.vpc_cidr, 4, 2), az = local.azs[0] }
    b = { cidr_block = cidrsubnet(var.vpc_cidr, 4, 3), az = local.azs[1] }
  }

  # Resolve which NAT Gateway each private route table should use: with
  # single_nat_gateway, every AZ shares the one NAT Gateway that was
  # created; otherwise each AZ gets its own, matched by logical key.
  nat_gateway_single_id = values(module.nat_gateway.nat_gateway_ids_by_key)[0]

  private_route_tables = {
    for key, subnet in module.subnets.private_subnets_by_key :
    key => {
      subnet_id      = subnet.id
      nat_gateway_id = var.single_nat_gateway ? local.nat_gateway_single_id : module.nat_gateway.nat_gateway_ids_by_key[key]
    }
  }

  interface_endpoints = var.enable_vpc_interface_endpoints ? [
    "ssm",
    "ssmmessages",
    "ec2messages",
    "secretsmanager",
    "logs",
    "monitoring",
  ] : []

  # Minimal first-boot bootstrap only: it exists to guarantee the instance
  # is reachable over SSM the moment it launches. All real configuration
  # (Docker, Nginx, hardening, the application itself, monitoring agents)
  # is applied afterwards by Ansible, driven by the Jenkins pipeline via
  # dynamic inventory generated from these Terraform outputs.
  app_user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    systemctl enable --now amazon-ssm-agent
  EOT
}

module "vpc" {
  source = "../../modules/networking/vpc"

  name       = local.name_prefix
  cidr_block = var.vpc_cidr
  tags       = local.common_tags
}

module "subnets" {
  source = "../../modules/networking/subnets"

  name_prefix     = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  tags            = local.common_tags
}

module "internet_gateway" {
  source = "../../modules/networking/internet-gateway"

  name   = "${local.name_prefix}-igw"
  vpc_id = module.vpc.vpc_id
  tags   = local.common_tags
}

module "nat_gateway" {
  source = "../../modules/networking/nat-gateway"

  name_prefix           = local.name_prefix
  public_subnets_by_key = module.subnets.public_subnets_by_key
  single_nat_gateway    = var.single_nat_gateway
  tags                  = local.common_tags
}

module "route_tables" {
  source = "../../modules/networking/route-tables"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  internet_gateway_id  = module.internet_gateway.internet_gateway_id
  public_subnet_ids    = module.subnets.public_subnet_ids
  private_route_tables = local.private_route_tables
  tags                 = local.common_tags
}

module "alb_security_group" {
  source = "../../modules/networking/security-groups"

  name        = "${local.name_prefix}-alb-sg"
  description = "Internet-facing ALB: allow HTTP/HTTPS in, everything out"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  tags = local.common_tags
}

module "app_security_group" {
  source = "../../modules/networking/security-groups"

  name        = "${local.name_prefix}-app-sg"
  description = "Application instances: allow traffic from ALB and, optionally, admin SSH"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = concat(
    [
      {
        description              = "App traffic from ALB"
        from_port                = var.app_port
        to_port                  = var.app_port
        protocol                 = "tcp"
        source_security_group_id = module.alb_security_group.security_group_id
      }
    ],
    [
      for cidr in var.admin_cidr_blocks : {
        description = "Admin SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [cidr]
      }
    ]
  )

  tags = local.common_tags
}

module "vpc_endpoints_security_group" {
  source = "../../modules/networking/security-groups"

  name        = "${local.name_prefix}-vpce-sg"
  description = "Interface VPC endpoints: allow HTTPS from within the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTPS from inside the VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  ]

  tags = local.common_tags
}

module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  name_prefix         = local.name_prefix
  vpc_id              = module.vpc.vpc_id
  gateway_endpoints   = ["s3", "dynamodb"]
  route_table_ids     = concat([module.route_tables.public_route_table_id], values(module.route_tables.private_route_table_ids))
  interface_endpoints = local.interface_endpoints
  subnet_ids          = module.subnets.private_subnet_ids
  security_group_ids  = [module.vpc_endpoints_security_group.security_group_id]
  tags                = local.common_tags
}

module "app_instance_role" {
  source = "../../modules/iam/ec2-instance-role"

  name_prefix             = "${local.name_prefix}-app"
  enable_ssm              = true
  enable_cloudwatch_agent = true

  # Scoped, least-privilege access to exactly the app's own secret,
  # data bucket, and DynamoDB table (declared further down this file;
  # Terraform resolves the dependency graph regardless of file order).
  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadOwnSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [module.app_secret.secret_arn]
      },
      {
        Sid      = "ReadWriteOwnDataBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [module.app_data_bucket.bucket_arn, "${module.app_data_bucket.bucket_arn}/*"]
      },
      {
        Sid      = "ReadWriteOwnTable"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"]
        Resource = [module.app_table.table_arn, "${module.app_table.table_arn}/index/*"]
      },
      {
        Sid      = "UseAppKmsKey"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = [module.app_kms.key_arn]
      }
    ]
  })

  tags = local.common_tags
}

module "alb" {
  source = "../../modules/compute/alb"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnets.public_subnet_ids
  security_group_ids = [module.alb_security_group.security_group_id]
  internal           = false
  target_port        = var.app_port
  health_check_path  = var.health_check_path
  certificate_arn    = null # dev serves HTTP only; set this once an ACM cert exists for the domain
  tags               = local.common_tags
}

module "app_launch_template" {
  source = "../../modules/compute/launch-template"

  name_prefix                = "${local.name_prefix}-app"
  instance_type              = var.instance_type
  vpc_security_group_ids     = [module.app_security_group.security_group_id]
  iam_instance_profile_name  = module.app_instance_role.instance_profile_name
  user_data                  = local.app_user_data
  enable_detailed_monitoring = false
  tags                       = local.common_tags
}

module "app_autoscaling_group" {
  source = "../../modules/compute/autoscaling-group"

  name_prefix             = "${local.name_prefix}-app"
  launch_template_id      = module.app_launch_template.launch_template_id
  launch_template_version = module.app_launch_template.launch_template_latest_version
  vpc_zone_identifier     = module.subnets.private_subnet_ids
  target_group_arns       = [module.alb.target_group_arn]
  min_size                = var.asg_min_size
  max_size                = var.asg_max_size
  desired_capacity        = var.asg_desired_capacity
  health_check_type       = var.asg_health_check_type
  target_cpu_utilization  = 60
  tags                    = local.common_tags
}

# ---------------------------------------------------------------------
# Supporting services: encryption, storage, secrets, data, notifications
# and monitoring for the application deployed above.
# ---------------------------------------------------------------------

module "app_kms" {
  source = "../../modules/security/kms"

  name        = "${local.name_prefix}-app"
  description = "Encrypts ${local.name_prefix} application data: S3 objects, Secrets Manager secrets, DynamoDB table, SNS messages, CloudWatch Logs."

  # Deliberately no key_users here: that would create a dependency cycle
  # with app_instance_role, which itself needs this key's ARN for its
  # inline policy (below). The key's baseline "root account full access"
  # statement already delegates authorization to IAM, so the instance
  # role's own inline kms:Decrypt/GenerateDataKey grant is sufficient —
  # no key-policy-side grant is needed as well.
  #
  # CloudWatch Logs is a real exception to that: unlike most services,
  # it will not encrypt a log group with a customer-managed key on the
  # strength of an IAM grant alone — the key policy itself must
  # explicitly trust the logs.<region>.amazonaws.com service principal,
  # scoped to this specific log group via the EncryptionContext
  # condition. Found this the hard way: CreateLogGroup failed with
  # AccessDeniedException without it.
  additional_statements = [
    {
      Sid    = "AllowCloudWatchLogsEncryption"
      Effect = "Allow"
      Principal = {
        Service = "logs.${var.aws_region}.amazonaws.com"
      }
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      Resource = "*"
      Condition = {
        ArnEquals = {
          "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/${var.environment}/app"
        }
      }
    }
  ]

  tags = local.common_tags
}

module "app_data_bucket" {
  source = "../../modules/storage/s3"

  bucket_name        = "${local.name_prefix}-app-data-${data.aws_caller_identity.current.account_id}"
  versioning_enabled = true
  kms_key_arn        = module.app_kms.key_arn

  lifecycle_rules = [
    {
      id                                 = "expire-noncurrent-versions"
      enabled                            = true
      noncurrent_version_expiration_days = 90
    }
  ]

  tags = local.common_tags
}

module "app_secret" {
  source = "../../modules/security/secrets-manager"

  name                     = "${local.name_prefix}-app-secret"
  description              = "Placeholder application secret (e.g. database credentials) for ${local.name_prefix}. Populate the real value out-of-band; Terraform only provisions the container."
  kms_key_arn              = module.app_kms.key_arn
  generate_random_password = true
  recovery_window_in_days  = 7
  tags                     = local.common_tags
}

module "app_table" {
  source = "../../modules/database/dynamodb"

  table_name = "${local.name_prefix}-app-table"
  hash_key = {
    name = "id"
    type = "S"
  }
  point_in_time_recovery = true
  kms_key_arn            = module.app_kms.key_arn
  tags                   = local.common_tags
}

module "alerts_topic" {
  source = "../../modules/observability/sns"

  name        = "${local.name_prefix}-alerts"
  kms_key_arn = module.app_kms.key_arn

  # No destination hardcoded here on purpose (generic/parameterized
  # environment). Add real subscriptions in terraform.tfvars, e.g.:
  # sns_subscriptions = [{ protocol = "email", endpoint = "ops@example.com" }]
  subscriptions = var.sns_subscriptions

  tags = local.common_tags
}

module "app_observability" {
  source = "../../modules/observability/cloudwatch"

  log_group_names       = ["/${var.project_name}/${var.environment}/app"]
  log_retention_days    = 30
  log_group_kms_key_arn = module.app_kms.key_arn

  alarms = {
    "${local.name_prefix}-app-high-cpu" = {
      alarm_description   = "Average CPU across the app Auto Scaling Group exceeded 80% for 10 minutes."
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      statistic           = "Average"
      period              = 300
      evaluation_periods  = 2
      threshold           = 80
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        AutoScalingGroupName = module.app_autoscaling_group.autoscaling_group_name
      }
      alarm_actions = [module.alerts_topic.topic_arn]
      ok_actions    = [module.alerts_topic.topic_arn]
    }
    "${local.name_prefix}-alb-5xx-errors" = {
      alarm_description   = "ALB returned 10+ target-origin 5xx responses in a 5 minute window."
      metric_name         = "HTTPCode_Target_5XX_Count"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Sum"
      period              = 300
      evaluation_periods  = 1
      threshold           = 10
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        LoadBalancer = module.alb.alb_arn_suffix
      }
      alarm_actions      = [module.alerts_topic.topic_arn]
      ok_actions         = [module.alerts_topic.topic_arn]
      treat_missing_data = "notBreaching"
    }
    "${local.name_prefix}-alb-unhealthy-hosts" = {
      alarm_description   = "One or more targets behind the ALB are unhealthy."
      metric_name         = "UnHealthyHostCount"
      namespace           = "AWS/ApplicationELB"
      statistic           = "Average"
      period              = 60
      evaluation_periods  = 3
      threshold           = 0
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        LoadBalancer = module.alb.alb_arn_suffix
        TargetGroup  = module.alb.target_group_arn_suffix
      }
      alarm_actions      = [module.alerts_topic.topic_arn]
      ok_actions         = [module.alerts_topic.topic_arn]
      treat_missing_data = "notBreaching"
    }
  }

  tags = local.common_tags
}
