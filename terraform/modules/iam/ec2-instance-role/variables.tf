variable "name_prefix" {
  description = "Prefix used when naming the IAM role and instance profile, e.g. cloudforge-dev-app."
  type        = string
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore so instances are reachable via SSM Session Manager instead of requiring open SSH."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Attach CloudWatchAgentServerPolicy so instances can ship metrics/logs to CloudWatch."
  type        = bool
  default     = true
}

variable "additional_managed_policy_arns" {
  description = "Extra AWS-managed or customer-managed policy ARNs to attach to the role, beyond SSM/CloudWatch."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy document (JSON) for permissions specific to this workload (e.g. read access to one Secrets Manager secret). Left null to attach none."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN applied to the role for defense-in-depth."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge onto the IAM role."
  type        = map(string)
  default     = {}
}
