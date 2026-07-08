variable "name" {
  description = "Name of the IAM role Jenkins assumes to run Terraform/Ansible against AWS, e.g. cloudforge-jenkins-deploy."
  type        = string
}

variable "project_name" {
  description = "Project identifier, used to scope the inline policy's resource ARNs/conditions to this project's resources where AWS actions support it."
  type        = string
}

variable "trusted_principal_arns" {
  description = "IAM principal ARNs allowed to assume this role (typically the Jenkins controller/agent instance role's ARN). Must be non-empty: an assume-role policy that trusts nobody defeats the role's purpose."
  type        = list(string)

  validation {
    condition     = length(var.trusted_principal_arns) > 0
    error_message = "trusted_principal_arns must list at least one principal ARN allowed to assume this role."
  }
}

variable "external_id" {
  description = "Optional sts:ExternalId required on AssumeRole calls, as an extra confused-deputy safeguard. Recommended when the trusted principal is outside your own account."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "AWS-managed policy ARNs attached to the role. PowerUserAccess covers most provisioning actions but deliberately excludes IAM management, which is granted separately via the scoped inline policy below."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/PowerUserAccess"]
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN applied to this role for defense-in-depth."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration (seconds) for assumed sessions."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1h) and 43200 (12h) seconds."
  }
}

variable "tags" {
  description = "Additional tags to merge onto the IAM role."
  type        = map(string)
  default     = {}
}
