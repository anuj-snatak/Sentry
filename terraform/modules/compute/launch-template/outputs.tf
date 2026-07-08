output "launch_template_id" {
  description = "ID of the created launch template."
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "Latest version number of the launch template, for pinning the Auto Scaling Group to it."
  value       = aws_launch_template.this.latest_version
}
