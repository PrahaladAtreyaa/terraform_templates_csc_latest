variable clientId {}
variable clientSecret {}
variable region {}
variable subscriptionId {}
variable tenantId {}
variable isNewResourceGroup {
  type = bool
  default = false
}
variable newResourceGroup {
  default = "test-rg-dnd"
}
variable existingResourceGroup { 
  default = "cpg-dnd"
}
variable os {
  type    = string
  default = "Windows" #windows , Linux
}
variable storageAccountName {
  default = "testcpgsa0035"
}
variable functionAppName {
  type = string
  default = "testfa00035"
}
variable applicationName {
  type = string
  default = "function-app"
}
variable runTimeEngine {
  default = "node"  #java, node, dotnet, powershell_core ; python - only supported for os linux
}
variable runTimeVersion {
  type    = string
  default = "~18" # WINDOWS : NodeJs: ~12, ~14, ~16 and ~18. ; DotNet: v3.0, v4.0 v6.0 and v7.0 ; Java : 1.8, 11 & 17 ; PowerShell : 7 and 7.2. LINUX : NodeJs: 12, 14, 16 and 18. ; DotNet: 3.1, 6.0 and 7.0 ; Java : 8, 11 & 17; PowerShell : 7 and 7.2. ; Python : 3.11, 3.10, 3.9, 3.8 and 3.7.
}
