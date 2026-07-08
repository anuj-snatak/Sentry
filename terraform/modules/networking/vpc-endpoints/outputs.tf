output "gateway_endpoint_ids" {
  description = "Map of service short name => Gateway VPC endpoint ID."
  value       = { for k, e in aws_vpc_endpoint.gateway : k => e.id }
}

output "interface_endpoint_ids" {
  description = "Map of service short name => Interface VPC endpoint ID."
  value       = { for k, e in aws_vpc_endpoint.interface : k => e.id }
}
