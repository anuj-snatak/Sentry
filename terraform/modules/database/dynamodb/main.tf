locals {
  key_attributes = concat(
    [var.hash_key],
    var.range_key != null ? [var.range_key] : [],
  )

  # Deduplicated by name: a GSI often reuses the table's own hash/range
  # key as its attributes, and DynamoDB rejects a table definition that
  # declares the same attribute name twice.
  all_attributes = {
    for attr in concat(local.key_attributes, var.additional_attributes) :
    attr.name => attr
  }
}

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key.name
  range_key    = var.range_key != null ? var.range_key.name : null

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  dynamic "attribute" {
    for_each = local.all_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? global_secondary_index.value.non_key_attributes : null
      read_capacity       = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
      write_capacity       = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute_name != null ? [var.ttl_attribute_name] : []
    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )
}
