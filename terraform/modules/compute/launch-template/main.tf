data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.name_prefix}-lt-"
  image_id    = coalesce(var.ami_id, try(data.aws_ami.amazon_linux_2023[0].id, null))

  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids
  user_data              = var.user_data != null ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # Enforce IMDSv2 (session-token-required) across every instance the
  # Auto Scaling Group launches from this template.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
      encrypted   = true
      kms_key_id  = var.kms_key_id
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-lt"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
