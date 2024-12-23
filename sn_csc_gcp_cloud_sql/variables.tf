variable "project" {
  type = string
}

variable "region" {
  type    = string
}

variable "credentials" {
  type = string
}

variable "sql_instance_name" {
  type    = string
}

variable "sql_database_version" {
  type    = string
}

variable "sql_tier" {
  type    = string
}

variable "sql_disk_size" {
  type    = number
}

variable "sql_disk_type" {
  type    = string
}

variable "sql_edition" {
  type    = string
}

variable "sql_root_password" {
  type    = string
  default = ""
}

variable "sql_encryption_key_name" {
  type    = string
  default = ""
}

variable "tf_delete_protection" {
  type    = bool
  default =  true
}

variable "gcp_delete_protection" {
  type    = bool
  default = false
}

variable "activation_policy" {
  type = string
  default = "ALWAYS"
}

variable "backup_configuration_enable" {
  type    = bool
  default = true
}
variable "bc_binary_log_enabled" {
  type    = bool
  default = false
}
variable "bc_point_in_time_recovery_enabled" {
  type    = bool
  default = false
}

variable "availability_type" {
  type = string
  default = "ZONAL"
}

variable "sql_username_password" {
    type = list(object({
        name = string
        password = string
    }))
    default = []
}
