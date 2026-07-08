output "key_id" {
  description = "ID of the created KMS key."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "ARN of the created KMS key."
  value       = aws_kms_key.this.arn
}

output "alias_name" {
  description = "Alias of the created KMS key."
  value       = aws_kms_alias.this.name
}
