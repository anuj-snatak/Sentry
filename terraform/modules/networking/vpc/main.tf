resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# The default security group is created automatically by AWS with an
# open self-referencing rule set. Locking it down (no rules at all) so
# nothing can accidentally rely on it instead of a purpose-built SG.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-default-sg-locked"
    }
  )
}
