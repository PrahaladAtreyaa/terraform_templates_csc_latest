resource "google_sql_database_instance" "csc_cloud_sql_instance" {
  name             = var.sql_instance_name
  database_version = var.sql_database_version
  project          = var.project
  region           = var.region
  root_password    = var.sql_root_password
  encryption_key_name = var.sql_encryption_key_name
  deletion_protection = var.tf_delete_protection

  settings {
    tier       = var.sql_tier
    disk_size  = var.sql_disk_size
    disk_type  = var.sql_disk_type
    edition    = var.sql_edition
    deletion_protection_enabled = var.gcp_delete_protection
    activation_policy = var.activation_policy
    backup_configuration {
      enabled           = var.backup_configuration_enable
      binary_log_enabled = var.bc_binary_log_enabled
      point_in_time_recovery_enabled = var.bc_point_in_time_recovery_enabled
    }
  }
}

resource "google_sql_user" "csc_cloud_sql_user" {
  count = length(var.sql_username_password)
  name     = var.sql_username_password[count.index].name
  instance = google_sql_database_instance.csc_cloud_sql_instance.name
  password = var.sql_username_password[count.index].password
}
