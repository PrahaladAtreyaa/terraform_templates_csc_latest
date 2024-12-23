variable "project" {}

variable "region" {}

variable "credentials"{}

variable "lb_zone" {}

variable "network" {}

variable "subnet_id" {}

variable "attach_vm" {
  type = bool
}

variable "lb_vm_instances" {
  type    = list(string)
}

variable "url_map_name"{}