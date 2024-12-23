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

variable "boot_disk_size_gb" {}

variable "boot_disk_type" {}

variable "additional_disks" {
  type        = list(object({
    size_gb      = number
    type         = string
  }))
  default =[]
}

variable "vm_username" {
  type    = string
  default = ""
}

variable "vm_password" {
  type    = string
  default = ""
}