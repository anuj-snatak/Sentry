variable "name_prefix" {
  description = "Prefix used when naming VPC endpoints."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC endpoints are created in."
  type        = string
}

variable "gateway_endpoints" {
  description = "AWS service short names to create Gateway endpoints for (e.g. [\"s3\", \"dynamodb\"]). Gateway endpoints are free and attach to route tables, not subnets."
  type        = list(string)
  default     = ["s3", "dynamodb"]
}

variable "route_table_ids" {
  description = "Route table IDs to associate with every Gateway endpoint."
  type        = list(string)
  default     = []
}

variable "interface_endpoints" {
  description = "AWS service short names to create Interface endpoints for (e.g. [\"ssm\", \"ssmmessages\", \"ec2messages\", \"secretsmanager\", \"logs\", \"monitoring\"]). Interface endpoints are billed hourly plus data processing."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs Interface endpoint ENIs are placed in (typically private subnets)."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs attached to Interface endpoint ENIs. Must allow inbound 443 from callers."
  type        = list(string)
  default     = []
}

variable "private_dns_enabled" {
  description = "Whether Interface endpoints get private DNS, so in-VPC callers resolve the standard AWS service hostname to the endpoint automatically."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge onto every endpoint."
  type        = map(string)
  default     = {}
}
