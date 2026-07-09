variable "name" {
  description = "Name tag for the instance, e.g. cloudforge-dev-bastion."
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch. Leave null to auto-select the latest Amazon Linux 2023 x86_64 AMI."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID the instance is launched into."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the instance."
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "Name of an IAM instance profile to attach (see the ec2-instance-role module)."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IP. Should stay false for anything other than a bastion in a public subnet."
  type        = bool
  default     = false
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

variable "user_data" {
  description = "Optional user_data script (plain text, not base64) run on first boot."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge onto the instance."
  type        = map(string)
  default     = {}
}
