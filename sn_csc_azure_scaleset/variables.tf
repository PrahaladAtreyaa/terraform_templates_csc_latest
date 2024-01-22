variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string

}
variable "application_port" {
  type    = number
  default = 80

}
variable "location" {
  description = "Location where resources will be created"
}
variable "isNewResourceGroup" {
  type    = bool
}
variable "newResourceGroup" {
  type        = string
  description = "Name of the resource group in which the resources will be created"
}
variable "existingResourceGroup" {

}
variable "vmName" {
  type = string

}
variable "network" {

}
variable "subnet" {

}
variable "networkResourceGroup" {

}
variable "size" {

}
variable "admin_user" {
  description = "User name to use as the admin account on the VMs that will be part of the VM scale set"

}
variable "isPassword" {
  type = bool
}
variable "admin_password" {
  description = "Default password for admin account"
}
variable "instanceCount" {
  type = number
}
variable "diskSizeGB" {
  type = number
}
variable "publicKey" {
  
}
variable "storage_profile_publisher" {

}
variable "storage_profile_offer" {

}
variable "storage_profile_sku" {

}