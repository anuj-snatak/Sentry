output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the dev VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs, e.g. for an ALB."
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs, e.g. for application instances."
  value       = module.subnets.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public (Elastic) IPs of NAT Gateways, useful for allow-listing egress from private subnets."
  value       = module.nat_gateway.nat_gateway_public_ips
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB, consumed by the compute phase."
  value       = module.alb_security_group.security_group_id
}

output "app_security_group_id" {
  description = "Security group ID for application instances, consumed by the compute phase."
  value       = module.app_security_group.security_group_id
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = module.route_tables.public_route_table_id
}

output "private_route_table_ids" {
  description = "Map of logical AZ key => private route table ID."
  value       = module.route_tables.private_route_table_ids
}

output "alb_dns_name" {
  description = "DNS name of the application ALB. Point a browser or Route53 record here."
  value       = module.alb.alb_dns_name
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group, used by inventory generation to discover live instances."
  value       = module.app_autoscaling_group.autoscaling_group_name
}

output "app_instance_role_arn" {
  description = "ARN of the IAM role attached to application instances."
  value       = module.app_instance_role.role_arn
}

output "app_kms_key_arn" {
  description = "ARN of the KMS key encrypting this environment's application data."
  value       = module.app_kms.key_arn
}

output "app_data_bucket_name" {
  description = "Name of the application's S3 data bucket."
  value       = module.app_data_bucket.bucket_id
}

output "app_secret_arn" {
  description = "ARN of the application's Secrets Manager secret."
  value       = module.app_secret.secret_arn
}

output "app_table_name" {
  description = "Name of the application's DynamoDB table."
  value       = module.app_table.table_name
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic CloudWatch alarms and pipeline notifications publish to."
  value       = module.alerts_topic.topic_arn
}
