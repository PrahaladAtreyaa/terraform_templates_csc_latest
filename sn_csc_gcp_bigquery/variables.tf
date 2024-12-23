variable "project" {}
variable "region" {}

variable "dataset_id" {
  type = string
}

variable "table_id" {
  type = string
}
variable "table_schema" {
  type = string
  default = ""
}
variable "partition_type"{
  type = string
  default = "DAY"
}

variable "enable_partitioning" {
  type = bool
  default = false
}

variable "clustering_fields" {
  type    = list(string)
}

variable "create_from_source"{
  type = bool
  default = false
}

variable "autodetect_schema" {
  type = bool
  default = false
}

variable "source_uris" {
  description = "List of URIs of the source files in Google Cloud Storage."
  type        = list(string)
  default     = []
}

variable "source_format" {
  type = string
  default = "NEWLINE_DELIMITED_JSON"
}

variable "default_table_expiration_ms" {
  type = number
  default = 0
}

variable "expiration_time" {
  type = number
  default = 0
}

variable "credentials" {}
