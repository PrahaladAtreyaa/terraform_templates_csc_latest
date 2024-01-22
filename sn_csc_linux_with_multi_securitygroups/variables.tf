variable "access_key" {}

variable "secret_key" {}

variable "region" {}

variable "subnet" {}

variable "network" {}

variable "instancetype" {}

variable "ami" {}

variable "keyname" {}

variable "vpc_security_group_ids" {
  type= set(string)
}
