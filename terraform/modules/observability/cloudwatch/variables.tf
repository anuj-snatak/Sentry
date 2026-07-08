variable "log_group_names" {
  description = "CloudWatch Log Group names to create, e.g. [\"/cloudforge/dev/app\", \"/cloudforge/dev/nginx\"]."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention period applied to every created log group."
  type        = number
  default     = 30
}

variable "log_group_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt log group data at rest."
  type        = string
  default     = null
}

variable "alarms" {
  description = "Map of alarm key => alarm config. Each entry creates one aws_cloudwatch_metric_alarm."
  type = map(object({
    alarm_description  = string
    metric_name        = string
    namespace          = string
    statistic          = string
    period              = number
    evaluation_periods  = number
    threshold           = number
    comparison_operator = string
    dimensions          = optional(map(string), {})
    alarm_actions       = optional(list(string), [])
    ok_actions           = optional(list(string), [])
    treat_missing_data   = optional(string, "missing")
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to merge onto every log group and alarm."
  type        = map(string)
  default     = {}
}
