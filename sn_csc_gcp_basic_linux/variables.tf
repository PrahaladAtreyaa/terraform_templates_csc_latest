variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "credentials" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "zone" {
  type = string
}

variable "auto_delete" {
  type = bool
}

variable "image" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "network" {
  type = string
}

variable "vm_desired_status" {
  type    = string
  default = "RUNNING"
}

variable "ssh_pub_key" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type    = string
  default = ""
}

variable "vm_username" {
  type    = string
  default = ""
}

variable "vm_password" {
  type    = string
  default = ""
}

variable "authentication_type" {
  type    = string
  default = "ssh_key"
}