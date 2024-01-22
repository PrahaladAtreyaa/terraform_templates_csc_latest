
# Declare input variables
variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "bucket_name" {}
variable "encryption_kms_key" {
  default = "aws/s3"
}
variable "encryption_key_type" {
  default = "AES256"
}
variable "bucket_key" {
  default=false
}