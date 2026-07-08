variable "name_prefix" {
  description = "Prefix used when naming NAT Gateways and their Elastic IPs."
  type        = string
}

variable "public_subnets_by_key" {
  description = "Map of logical key => public subnet attributes (id, az), as emitted by the subnets module. One NAT Gateway is created per entry unless single_nat_gateway is true."
  type = map(object({
    id   = string
    cidr = string
    az   = string
  }))
}

variable "single_nat_gateway" {
  description = "If true, create exactly one NAT Gateway (lower cost, single point of failure). If false, create one NAT Gateway per public subnet/AZ (highly available, higher cost)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge onto NAT Gateway and EIP resources."
  type        = map(string)
  default     = {}
}
