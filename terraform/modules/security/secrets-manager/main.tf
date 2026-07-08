resource "random_password" "this" {
  count = var.generate_random_password ? 1 : 0

  length           = var.random_password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = coalesce(var.secret_string, try(random_password.this[0].result, null))

  lifecycle {
    precondition {
      condition     = var.secret_string != null || var.generate_random_password
      error_message = "Either secret_string must be provided or generate_random_password must be true; a secret with no value would be pointless."
    }
  }
}
