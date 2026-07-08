variable "name" {
  description = "Name of the SNS topic, e.g. cloudforge-dev-alerts."
  type        = string
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt messages at rest. Leave null for the default AWS-managed key."
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "Subscriptions to create on the topic, e.g. [{ protocol = \"email\", endpoint = \"ops@example.com\" }]. Left empty by default so no real destination is hardcoded; add via tfvars."
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}

variable "allow_cloudwatch_publish" {
  description = "Allow the cloudwatch.amazonaws.com service principal to publish to this topic, so CloudWatch Alarms can notify it."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge onto the topic."
  type        = map(string)
  default     = {}
}
