variable "name_prefix" {
  description = "Prefix used when naming subnets, e.g. cloudforge-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC subnets are created in."
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnet configs keyed by a short logical name (e.g. \"a\", \"b\")."
  type = map(object({
    cidr_block = string
    az         = string
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnet configs keyed by a short logical name (e.g. \"a\", \"b\")."
  type = map(object({
    cidr_block = string
    az         = string
  }))
  default = {}
}

variable "map_public_ip_on_launch" {
  description = "Whether instances launched into public subnets get an auto-assigned public IP."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge onto every subnet."
  type        = map(string)
  default     = {}
}
