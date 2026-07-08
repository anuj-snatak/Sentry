output "public_subnet_ids" {
  description = "List of created public subnet IDs."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of created private subnet IDs."
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnets_by_key" {
  description = "Map of logical key => public subnet attributes, for callers that need AZ-aware wiring (e.g. one NAT gateway per AZ)."
  value = {
    for k, s in aws_subnet.public : k => {
      id   = s.id
      cidr = s.cidr_block
      az   = s.availability_zone
    }
  }
}

output "private_subnets_by_key" {
  description = "Map of logical key => private subnet attributes, for callers that need AZ-aware wiring."
  value = {
    for k, s in aws_subnet.private : k => {
      id   = s.id
      cidr = s.cidr_block
      az   = s.availability_zone
    }
  }
}
