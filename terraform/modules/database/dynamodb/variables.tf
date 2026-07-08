variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (recommended default, scales to zero) or PROVISIONED (predictable workloads, needs read/write capacity)."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be either \"PAY_PER_REQUEST\" or \"PROVISIONED\"."
  }
}

variable "read_capacity" {
  description = "Provisioned read capacity units. Only used when billing_mode is PROVISIONED."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Provisioned write capacity units. Only used when billing_mode is PROVISIONED."
  type        = number
  default     = 5
}

variable "hash_key" {
  description = "Partition key: { name, type } where type is one of S, N, B."
  type = object({
    name = string
    type = string
  })
}

variable "range_key" {
  description = "Optional sort key: { name, type }."
  type = object({
    name = string
    type = string
  })
  default = null
}

variable "additional_attributes" {
  description = "Extra attributes referenced by global_secondary_indexes but not part of the table's own hash/range key."
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "global_secondary_indexes" {
  description = "GSIs to create on the table."
  type = list(object({
    name             = string
    hash_key         = string
    range_key        = optional(string, null)
    projection_type  = optional(string, "ALL")
    non_key_attributes = optional(list(string), null)
  }))
  default = []
}

variable "point_in_time_recovery" {
  description = "Enable continuous backups / point-in-time recovery."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the table. Leave null to use the AWS-owned default key."
  type        = string
  default     = null
}

variable "ttl_attribute_name" {
  description = "Attribute name used for item TTL expiry. Leave null to disable TTL."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge onto the table."
  type        = map(string)
  default     = {}
}
