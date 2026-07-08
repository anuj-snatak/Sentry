output "role_name" {
  description = "Name of the created IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the created IAM role."
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "Name of the created IAM instance profile, for use in a launch template."
  value       = aws_iam_instance_profile.this.name
}

output "instance_profile_arn" {
  description = "ARN of the created IAM instance profile."
  value       = aws_iam_instance_profile.this.arn
}
