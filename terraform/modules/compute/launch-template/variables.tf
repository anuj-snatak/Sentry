variable "name_prefix" {
  description = "Prefix used when naming the launch template, e.g. cloudforge-dev-app."
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch. Leave null to auto-select the latest Amazon Linux 2023 x86_64 AMI."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type used by the Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to launched instances."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile attached to launched instances (see the ec2-instance-role module)."
  type        = string
}

variable "user_data" {
  description = "Optional user_data script (plain text, not base64-encoded here). Typically installs an SSM/CloudWatch bootstrap and hands off to Ansible for the rest of configuration."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB. Must be >= the source AMI's snapshot size or instance launch fails validation; Amazon Linux 2023's current AMI snapshot is 30 GiB."
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "KMS key ARN/ID used to encrypt the root EBS volume. Leave null to use the account default aws/ebs key."
  type        = string
  default     = null
}

variable "enable_detailed_monitoring" {
  description = "Enable EC2 detailed (1-minute) CloudWatch monitoring instead of the default 5-minute metrics."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged onto the launch template and every instance/volume it creates."
  type        = map(string)
  default     = {}
}
