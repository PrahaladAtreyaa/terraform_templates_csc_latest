locals {
  schema_json = var.table_schema
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.dataset_id
  location                    = var.region
  delete_contents_on_destroy = true
  default_table_expiration_ms =  (var.default_table_expiration_ms > 3600000) ? var.default_table_expiration_ms : null
}

resource "google_bigquery_table" "table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.table_id
  deletion_protection=false
  expiration_time = (var.expiration_time > 0) ? var.expiration_time : null

  dynamic "time_partitioning" {
    for_each = (!var.create_from_source && var.enable_partitioning)  ? [1] : []
    content {
      type = var.partition_type
    }
  }

  clustering = (!var.create_from_source && length(var.clustering_fields) > 0) ? var.clustering_fields : null

  # Either specify source_uris or omit them based on user input
  dynamic "external_data_configuration" {
    for_each = var.create_from_source ? [1] : []
    content {
      source_format = var.source_format
      autodetect  = var.autodetect_schema
      source_uris   = var.source_uris
    }
  }

  schema =  var.autodetect_schema ? null : local.schema_json
}
