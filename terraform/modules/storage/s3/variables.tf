variable "bucket_name" {
  description = "Globally-unique S3 bucket name."
  type        = string
}

variable "versioning_enabled" {
  description = "Enable object versioning."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN used for SSE-KMS encryption. Leave null to use SSE-S3 (AES256) instead — required for buckets AWS services write to that don't support SSE-KMS, such as ALB access logs."
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access to the bucket. Should stay true for every bucket in this platform; there is no supported public-bucket use case."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it still contains objects. Useful for ephemeral dev buckets, dangerous everywhere else."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for object expiration/transition. Each entry becomes one dynamic lifecycle rule block."
  type = list(object({
    id                            = string
    enabled                       = bool
    prefix                        = optional(string, "")
    expiration_days               = optional(number, null)
    noncurrent_version_expiration_days = optional(number, null)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "bucket_policy_statements" {
  description = "Additional raw IAM policy statement objects (as they'd appear in a policy document's \"Statement\" list) appended to the bucket policy, alongside the baseline deny-insecure-transport statement this module always adds. Use this for service-specific grants such as ALB access log delivery."
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge onto the bucket."
  type        = map(string)
  default     = {}
}
