output "internet_gateway_id" {
  description = "ID of the created Internet Gateway."
  value       = aws_internet_gateway.this.id
}
