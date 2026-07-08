output "role_name" {
  description = "Name of the created Jenkins deploy IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the created Jenkins deploy IAM role. Jenkins' shared library assumes this via sts:AssumeRole before running Terraform/Ansible (see shared-library/src/com/cloudforge/pipeline/AwsUtils.groovy)."
  value       = aws_iam_role.this.arn
}
