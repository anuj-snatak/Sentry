variable "name_prefix" {
  description = "Prefix used when naming the ALB and its target group, e.g. cloudforge-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the ALB and target group are created in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs the ALB's load balancer nodes are placed in (public subnets for an internet-facing ALB)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ALB."
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal (private) rather than internet-facing."
  type        = bool
  default     = false
}

variable "target_port" {
  description = "TCP port the application listens on behind the ALB."
  type        = number
}

variable "target_protocol" {
  description = "Protocol used between the ALB and targets."
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "HTTP path the target group health check requests."
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Seconds between health checks."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Seconds to wait for a health check response before considering it failed."
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Consecutive successful health checks required to mark a target healthy."
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Consecutive failed health checks required to mark a target unhealthy."
  type        = number
  default     = 3
}

variable "deregistration_delay" {
  description = "Seconds the ALB waits for in-flight requests to complete before fully deregistering a draining target."
  type        = number
  default     = 30
}

variable "certificate_arn" {
  description = "ACM certificate ARN for an HTTPS listener. Leave null to serve HTTP only (acceptable for dev/demo; prod should always set this)."
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "Seconds a connection can be idle before the ALB closes it."
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Prevent the ALB from being deleted via the API/Terraform until explicitly disabled. Should be true in qa/uat/prod."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name to write ALB access logs to. Leave null to disable access logging."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "Prefix (folder) within access_logs_bucket for this ALB's logs."
  type        = string
  default     = "alb"
}

variable "tags" {
  description = "Additional tags to merge onto the ALB and target group."
  type        = map(string)
  default     = {}
}
