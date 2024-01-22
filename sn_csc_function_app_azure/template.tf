resource "azurerm_resource_group" "tfresource" {
  count = "${var.isNewResourceGroup ? 1 : 0}"
  name = "${var.newResourceGroup}"
  location = "${var.region}"
}

resource "azurerm_storage_account" "tfresource" {
  name                     = var.storageAccountName
  resource_group_name      = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location                 = "${var.region}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "tfresource" {
  name                = "app-service-plan-${var.functionAppName}"
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location            = "${var.region}"
  os_type             = var.os
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "tfresource" {
  count               = "${var.os == "Windows" ? 1 : 0}"
  name                = var.functionAppName
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location            = "${var.region}"

  storage_account_name       = azurerm_storage_account.tfresource.name
  storage_account_access_key = azurerm_storage_account.tfresource.primary_access_key
  service_plan_id            = azurerm_service_plan.tfresource.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = var.runTimeEngine == "node" ? "https://${azurerm_storage_account.tfresource.name}.blob.core.windows.net/${azurerm_storage_container.tfresource[0].name}/${azurerm_storage_blob.tfresource[0].name}${data.azurerm_storage_account_blob_container_sas.tfresource[0].sas}" : "1",
    "WEBSITE_NODE_DEFAULT_VERSION": var.os == "Windows" ? "~14" : null
  }

  site_config {
    application_stack {
      node_version            = "${var.runTimeEngine == "node" ? var.runTimeVersion : null}"          #~12, ~14, ~16 and ~18.
      dotnet_version          = "${var.runTimeEngine == "dotnet" ? var.runTimeVersion : null}"       #v3.0, v4.0 v6.0 and v7.0
      java_version            = "${var.runTimeEngine == "java" ? var.runTimeVersion : null}"           #1.8, 11 & 17
      powershell_core_version = "${var.runTimeEngine == "powershellcore" ? var.runTimeVersion : null}"  #7 and 7.2.
    }
  }
}

resource "azurerm_linux_function_app" "tfresource" {
  count               = "${var.os == "Linux" ? 1 : 0}"
  name                = var.functionAppName
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location            = "${var.region}"

  storage_account_name       = azurerm_storage_account.tfresource.name
  storage_account_access_key = azurerm_storage_account.tfresource.primary_access_key
  service_plan_id            = azurerm_service_plan.tfresource.id

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = var.runTimeEngine == "node" ? "https://${azurerm_storage_account.tfresource.name}.blob.core.windows.net/${azurerm_storage_container.tfresource[0].name}/${azurerm_storage_blob.tfresource[0].name}${data.azurerm_storage_account_blob_container_sas.tfresource[0].sas}" : "1",
    "WEBSITE_NODE_DEFAULT_VERSION": var.os == "Windows" ? "~14" : null
  }

  site_config {
    application_stack {
      node_version            = "${var.runTimeEngine == "node" ? var.runTimeVersion : null}"             #12, 14, 16 and 18.
      dotnet_version          = "${var.runTimeEngine == "dotnet" ? var.runTimeVersion : null}"           #3.1, 6.0 and 7.0
      java_version            = "${var.runTimeEngine == "java" ? var.runTimeVersion : null}"             #8, 11 & 17
      powershell_core_version = "${var.runTimeEngine == "powershell_core" ? var.runTimeVersion : null}"  #7 and 7.2.
      python_version          = "${var.runTimeEngine == "python" ? var.runTimeVersion : null}"           #3.11, 3.10, 3.9, 3.8 and 3.7.
    }
  }
}

data "archive_file" "tfresource" {
  count       = "${var.runTimeEngine == "node" ? 1 : 0}"
  type        = "zip"
  source_dir  = var.applicationName
  output_path = "${var.applicationName}.zip"
}

resource "azurerm_storage_container" "tfresource" {
    count                 = "${var.runTimeEngine == "node" ? 1 : 0}"
    name                  = "${var.functionAppName}-storage-container-functions"
    storage_account_name  = azurerm_storage_account.tfresource.name
    container_access_type = "private"
}

#Upload the above zip archive to azure storage block

resource "azurerm_storage_blob" "tfresource" {
  count                  = "${var.runTimeEngine == "node" ? 1 : 0}"
  name                   = "${filesha256(data.archive_file.tfresource[0].output_path)}.zip"
  storage_account_name   = azurerm_storage_account.tfresource.name
  storage_container_name = azurerm_storage_container.tfresource[0].name
  type                   = "Block"
  source = data.archive_file.tfresource[0].output_path
}

data "azurerm_storage_account_blob_container_sas" "tfresource" {
  count                  = "${var.runTimeEngine == "node" ? 1 : 0}"
  connection_string      = azurerm_storage_account.tfresource.primary_connection_string
  container_name         = azurerm_storage_container.tfresource[0].name

  start                  = "2023-07-17T00:00:00Z"
  expiry                 = "2030-07-25T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

output "function_app_default_hostname" {
  value       = "${var.os == "Windows" ? azurerm_windows_function_app.tfresource[0].default_hostname : azurerm_linux_function_app.tfresource[0].default_hostname}"
  description = "Deployed function app hostname"
}
