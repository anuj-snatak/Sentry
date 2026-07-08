output "instance_id" {
  description = "ID of the created EC2 instance."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance, if associate_public_ip_address is true."
  value       = aws_instance.this.public_ip
}
