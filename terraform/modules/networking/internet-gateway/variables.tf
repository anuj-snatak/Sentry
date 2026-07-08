variable "name" {
  description = "Name tag for the Internet Gateway."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the Internet Gateway attaches to."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge onto the Internet Gateway."
  type        = map(string)
  default     = {}
}
