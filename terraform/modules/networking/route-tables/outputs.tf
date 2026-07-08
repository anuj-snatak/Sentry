output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Map of logical key => private route table ID."
  value       = { for k, rt in aws_route_table.private : k => rt.id }
}
