output "alb_arn" {
  description = "ARN of the created ALB."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB, e.g. for a Route53 alias record."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53-compatible hosted zone ID of the ALB, for alias records."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group, consumed by the autoscaling-group module."
  value       = aws_lb_target_group.this.arn
}

output "alb_arn_suffix" {
  description = "Short ARN suffix (e.g. app/my-alb/50dc6c495c0c9188) used as a CloudWatch metric dimension for this load balancer."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Short ARN suffix used as a CloudWatch metric dimension for this target group."
  value       = aws_lb_target_group.this.arn_suffix
}
