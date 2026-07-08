variable "name" {
  description = "Name of the secret, e.g. cloudforge-dev-app-db-credentials."
  type        = string
}

variable "description" {
  description = "Description of what this secret holds and which workload consumes it."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the secret. Leave null to use the account default aws/secretsmanager key."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days Secrets Manager retains a deleted secret before permanent removal, during which deletion can be cancelled. Set to 0 only for throwaway dev secrets."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 (no recovery window) or between 7 and 30."
  }
}

variable "secret_string" {
  description = "Explicit secret value to store. Mutually exclusive in intent with generate_random_password (if both are set, secret_string wins). Never hardcode a real value directly in tfvars committed to git — pass it via -var, a CI secret, or an .auto.tfvars file excluded from version control."
  type        = string
  default     = null
  sensitive   = true
}

variable "generate_random_password" {
  description = "Generate a random password as the initial secret value instead of supplying one, e.g. for a database master password Terraform itself provisions."
  type        = bool
  default     = false
}

variable "random_password_length" {
  description = "Length of the generated password, when generate_random_password is true."
  type        = number
  default     = 32
}

variable "tags" {
  description = "Additional tags to merge onto the secret."
  type        = map(string)
  default     = {}
}
