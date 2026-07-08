variable "name_prefix" {
  description = "Prefix used when naming route tables."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC route tables are created in."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway used as the default route for the public route table."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs to associate with the single shared public route table."
  type        = list(string)
  default     = []
}

variable "private_route_tables" {
  description = "One private route table is created per map entry, with a default route to the given NAT Gateway and an association to the given subnet. Key is a short logical name (e.g. the AZ key \"a\"/\"b\")."
  type = map(object({
    subnet_id      = string
    nat_gateway_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to merge onto every route table."
  type        = map(string)
  default     = {}
}
