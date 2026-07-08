locals {
  # When single_nat_gateway is true, only the first public subnet (by key)
  # gets a NAT Gateway; every private route table then points at that one.
  # When false, every public subnet gets its own NAT Gateway for per-AZ HA.
  nat_subnets = var.single_nat_gateway ? {
    (sort(keys(var.public_subnets_by_key))[0]) = var.public_subnets_by_key[sort(keys(var.public_subnets_by_key))[0]]
  } : var.public_subnets_by_key
}

resource "aws_eip" "nat" {
  for_each = local.nat_subnets

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-eip-${each.key}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-${each.key}"
    }
  )

  depends_on = [aws_eip.nat]
}
