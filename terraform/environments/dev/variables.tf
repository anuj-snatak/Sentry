variable "project_name" {
  description = "Short project identifier used to prefix resource names, e.g. cloudforge."
  type        = string
  default     = "cloudforge"
}

variable "environment" {
  description = "Environment name. Fixed per environments/* directory; do not override via tfvars."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "This environment directory is dedicated to \"dev\"."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Team or individual responsible for this environment's resources, used for tagging/cost allocation."
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center tag applied to every resource for chargeback reporting."
  type        = string
  default     = "engineering"
}

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the dev VPC. Subnets are automatically carved out of this block."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR, e.g. 10.0.0.0/16."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway instead of one per AZ. true is cheaper and appropriate for dev; prod should set this to false for AZ-level fault isolation."
  type        = bool
  default     = true
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed SSH (22/tcp) access to application instances, e.g. a corporate VPN range. Left empty by default so no environment ships with open SSH until explicitly configured."
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "TCP port the application listens on behind the ALB."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port must be a valid TCP port between 1 and 65535."
  }
}

variable "enable_vpc_interface_endpoints" {
  description = "Whether to create Interface VPC endpoints (SSM, Secrets Manager, CloudWatch Logs) for private-subnet access to AWS APIs without NAT egress. Adds hourly cost per endpoint."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type used by the application Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "health_check_path" {
  description = "HTTP path the ALB target group health check requests on application instances."
  type        = string
  default     = "/health"
}

variable "asg_min_size" {
  description = "Minimum number of application instances."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of application instances."
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired number of application instances at creation time."
  type        = number
  default     = 2
}

variable "sns_subscriptions" {
  description = "Subscriptions for the alerts SNS topic, e.g. [{ protocol = \"email\", endpoint = \"ops@example.com\" }]. Left empty by default — no real destination is hardcoded."
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}
