output "nat_gateway_ids_by_key" {
  description = "Map of logical AZ key => NAT Gateway ID. Has a single entry when single_nat_gateway is true."
  value       = { for k, ng in aws_nat_gateway.this : k => ng.id }
}

output "nat_gateway_ids" {
  description = "Flat list of all created NAT Gateway IDs."
  value       = [for ng in aws_nat_gateway.this : ng.id]
}

output "nat_gateway_public_ips" {
  description = "Public (Elastic) IPs of the created NAT Gateways, useful for allow-listing egress traffic downstream."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}
