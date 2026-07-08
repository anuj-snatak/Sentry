variable "project_name" {
  description = "Short project identifier used to prefix backend resource names (e.g. cloudforge)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric/hyphen, start with a letter, 2-31 chars."
  }
}

variable "aws_region" {
  description = "AWS region the state backend resources are created in."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name used to store Terraform remote state for all environments."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name (lowercase, 3-63 chars)."
  }
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = "terraform-state-lock"
}

variable "enable_bucket_key" {
  description = "Enable S3 Bucket Key to reduce KMS request costs for state encryption."
  type        = bool
  default     = true
}

variable "jenkins_trusted_principal_arns" {
  description = "IAM principal ARNs (typically the Jenkins controller/agent's own instance role) allowed to assume the Jenkins deploy role. Leave empty to skip creating the role entirely (e.g. before Jenkins itself exists yet)."
  type        = list(string)
  default     = []
}

variable "jenkins_external_id" {
  description = "Optional sts:ExternalId required when assuming the Jenkins deploy role."
  type        = string
  default     = null
}

variable "jenkins_permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN applied to the Jenkins deploy role."
  type        = string
  default     = null
}
