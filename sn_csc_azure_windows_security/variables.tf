variable clientId {}
variable clientSecret {}
variable region {}
variable subscriptionId {}
variable tenantId {}

variable isNewResourceGroup {
  type = bool
}
variable newResourceGroup {}
variable existingResourceGroup {}
variable vmName {}

variable network {}
variable subnet {}
variable networkResourceGroup {}
variable nic {}
variable size {}
variable adminUserName {}
variable password {}

variable image_publisher {}
variable image_offer {}
variable image_sku {}
variable image_version {}

variable deleteOSDiskOnTerm {
  type = bool
}

variable isAdvancedNetwork {
  type = bool
}
variable nsgName {}
variable nsgResourceGroup {}
variable rdp {
  type = bool
}
variable http {
  type = bool
}
variable https {
  type = bool
}