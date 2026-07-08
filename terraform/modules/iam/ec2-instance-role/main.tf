locals {
  managed_policy_arns = concat(
    var.enable_ssm ? ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"] : [],
    var.enable_cloudwatch_agent ? ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"] : [],
    var.additional_managed_policy_arns,
  )
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${var.name_prefix}-instance-role"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = var.permissions_boundary_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-instance-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(local.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json != null ? 1 : 0

  name   = "${var.name_prefix}-instance-inline-policy"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.this.name

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-instance-profile"
    }
  )
}
