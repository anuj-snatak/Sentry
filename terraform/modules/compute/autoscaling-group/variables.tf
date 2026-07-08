variable "name_prefix" {
  description = "Prefix used when naming the Auto Scaling Group, e.g. cloudforge-dev-app."
  type        = string
}

variable "launch_template_id" {
  description = "ID of the launch template new instances are created from."
  type        = string
}

variable "launch_template_version" {
  description = "Launch template version to use. Pass \"$Latest\" to always track the newest version, or a pinned version number for controlled rollout."
  type        = string
  default     = "$Latest"
}

variable "vpc_zone_identifier" {
  description = "Subnet IDs the Auto Scaling Group launches instances into (typically private subnets)."
  type        = list(string)
}

variable "target_group_arns" {
  description = "ALB target group ARNs to register instances with."
  type        = list(string)
  default     = []
}

variable "min_size" {
  description = "Minimum number of instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances at creation time. Ignored on subsequent applies (see lifecycle block) so scaling activity isn't fought by Terraform."
  type        = number
  default     = 2
}

variable "health_check_type" {
  description = "Health check type: EC2 (instance status only) or ELB (also considers target group health)."
  type        = string
  default     = "ELB"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be either \"EC2\" or \"ELB\"."
  }
}

variable "health_check_grace_period" {
  description = "Seconds to wait after an instance launches before starting health checks, giving the application/Ansible time to become ready."
  type        = number
  default     = 300
}

variable "enable_instance_refresh" {
  description = "Roll instances gradually when the launch template changes (new AMI, new user_data) instead of leaving old instances running indefinitely."
  type        = bool
  default     = true
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum percentage of the group that must stay healthy during an instance refresh rollout."
  type        = number
  default     = 90
}

variable "enable_target_tracking_scaling" {
  description = "Attach a target-tracking scaling policy based on average CPU utilization."
  type        = bool
  default     = true
}

variable "target_cpu_utilization" {
  description = "Target average CPU utilization percentage for the scaling policy."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Additional tags propagated onto every launched instance."
  type        = map(string)
  default     = {}
}
