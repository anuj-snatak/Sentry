output "state_bucket_name" {
  description = "S3 bucket name to reference in each environment's backend.tf."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name to reference in each environment's backend.tf for state locking."
  value       = aws_dynamodb_table.lock.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Terraform state."
  value       = aws_kms_key.state.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used to encrypt Terraform state."
  value       = aws_kms_alias.state.name
}

output "jenkins_deploy_role_arn" {
  description = "ARN of the Jenkins deploy IAM role, or null if jenkins_trusted_principal_arns was left empty. Configure Jenkins credentials with this ARN once created."
  value       = try(module.jenkins_deploy_role[0].role_arn, null)
}
