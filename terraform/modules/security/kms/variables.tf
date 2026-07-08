variable "name" {
  description = "Short name used for the KMS alias, e.g. cloudforge-dev-app (becomes alias/cloudforge-dev-app)."
  type        = string
}

variable "description" {
  description = "Description of what this key encrypts, shown in the console."
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion actually happens."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "key_administrators" {
  description = "IAM principal ARNs granted full administrative control over the key (rotate, disable, schedule deletion), in addition to the account root."
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "IAM principal ARNs granted permission to encrypt/decrypt/generate data keys using this key (e.g. an application's EC2 instance role)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge onto the key."
  type        = map(string)
  default     = {}
}
