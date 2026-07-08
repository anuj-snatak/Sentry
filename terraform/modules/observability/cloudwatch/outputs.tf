output "log_group_arns" {
  description = "Map of log group name => ARN."
  value       = { for k, lg in aws_cloudwatch_log_group.this : k => lg.arn }
}

output "alarm_arns" {
  description = "Map of alarm key => ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.this : k => a.arn }
}
