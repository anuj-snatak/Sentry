resource "aws_sns_topic" "this" {
  name              = var.name
  kms_master_key_id = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_sns_topic_subscription" "this" {
  for_each = { for s in var.subscriptions : "${s.protocol}-${s.endpoint}" => s }

  topic_arn = aws_sns_topic.this.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    sid       = "AllowAccountPublishAndManage"
    effect    = "Allow"
    actions   = ["SNS:Publish", "SNS:Subscribe", "SNS:GetTopicAttributes", "SNS:SetTopicAttributes"]
    resources = [aws_sns_topic.this.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  dynamic "statement" {
    for_each = var.allow_cloudwatch_publish ? [1] : []
    content {
      sid       = "AllowCloudWatchAlarmsPublish"
      effect    = "Allow"
      actions   = ["SNS:Publish"]
      resources = [aws_sns_topic.this.arn]

      principals {
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.topic_policy.json
}
