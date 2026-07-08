resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = length(ingress.value.cidr_blocks) > 0 ? ingress.value.cidr_blocks : null
      security_groups = ingress.value.source_security_group_id != null ? [ingress.value.source_security_group_id] : null
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = length(egress.value.cidr_blocks) > 0 ? egress.value.cidr_blocks : null
      security_groups = egress.value.source_security_group_id != null ? [egress.value.source_security_group_id] : null
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  # Security groups referenced by other security groups (via
  # source_security_group_id) can't be destroyed while referenced;
  # creating the replacement before destroying the old one avoids
  # apply-time ordering failures during updates.
  lifecycle {
    create_before_destroy = true
  }
}
