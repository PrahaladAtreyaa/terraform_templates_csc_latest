resource "aws_dynamodb_table" "basic_table" {
  name                        = var.name
  billing_mode                = var.billing_mode
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  table_class                 = var.table_class
  deletion_protection_enabled = var.deletion_protection_enabled


  ttl {
      enabled        = var.ttl_enabled
      attribute_name = var.ttl_attribute_name
  }

  point_in_time_recovery {
      enabled = var.point_in_time_recovery_enabled
  }

  dynamic "attribute" {
      for_each = var.attributes

      content {
        name = attribute.value.attribute_name
        type = attribute.value.data_type
      }
  }

  dynamic "local_secondary_index" {
      for_each = var.local_secondary_indexes
      content {
        name               = local_secondary_index.value.index_name
        range_key          = local_secondary_index.value.sort_key
        projection_type    = local_secondary_index.value.attribute_projections
      }
  }

  dynamic "global_secondary_index" {
      for_each = var.global_secondary_indexes

      content {
        name               = global_secondary_index.value.name
        hash_key           = global_secondary_index.value.hash_key
        projection_type    = global_secondary_index.value.projection_type
        range_key          = lookup(global_secondary_index.value, "range_key", null)
      }
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
  }
}
