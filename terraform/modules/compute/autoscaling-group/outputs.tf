output "autoscaling_group_name" {
  description = "Name of the created Auto Scaling Group."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the created Auto Scaling Group."
  value       = aws_autoscaling_group.this.arn
}
