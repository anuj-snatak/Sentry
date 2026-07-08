variable "name" {
  description = "Name of the security group, e.g. cloudforge-dev-alb-sg."
  type        = string
}

variable "description" {
  description = "Description of the security group's purpose."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the security group is created in."
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules. Provide either cidr_blocks or source_security_group_id per rule, not both."
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    source_security_group_id = optional(string, null)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules. Defaults to a single allow-all rule if left empty."
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    source_security_group_id = optional(string, null)
  }))
  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "tags" {
  description = "Additional tags to merge onto the security group."
  type        = map(string)
  default     = {}
}
