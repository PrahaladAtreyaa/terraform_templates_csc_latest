terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

resource "azurerm_resource_group" "vmss" {
  count    = var.isNewResourceGroup ? 1 : 0
  name     = var.newResourceGroup
  location = var.location
}

data "azurerm_virtual_network" "tfresource" {
  name                = var.network
  resource_group_name = var.networkResourceGroup
}

data "azurerm_subnet" "tfresource" {
  name                 = var.subnet
  resource_group_name  = var.networkResourceGroup
  virtual_network_name = data.azurerm_virtual_network.tfresource.name
}

resource "azurerm_public_ip" "vmss" {
  name                = "${var.vmName}-public-ip"
  location            = var.location
  resource_group_name = var.isNewResourceGroup ? azurerm_resource_group.vmss[0].name : var.existingResourceGroup
  allocation_method   = "Static"

}

resource "azurerm_lb" "vmss" {
  name                = "${var.vmName}-lb"
  location            = var.location
  resource_group_name = var.isNewResourceGroup ? azurerm_resource_group.vmss[0].name : var.existingResourceGroup

  frontend_ip_configuration {
    name                          = "PublicIPAddress"
    public_ip_address_id          = azurerm_public_ip.vmss.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_public_ip.vmss]

}


resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "${var.vmName}-BackEndAddressPool"

}


resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id     = azurerm_lb.vmss.id
  resource_group_name = var.isNewResourceGroup ? azurerm_resource_group.vmss[0].name : var.existingResourceGroup
  frontend_port       = var.application_port
  backend_port        = var.application_port

  frontend_ip_configuration_name = "PublicIPAddress"
  name                           = "${var.vmName}-webServerLoadBalancerRuleWeb"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  depends_on                     = [azurerm_virtual_machine_scale_set.vmss, ]
}

locals {
  _isSSHKey = "${var.isPassword ? {} : { empty = true }}"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${var.vmName}-vmscaleset"
  location            = var.location
  resource_group_name = var.isNewResourceGroup ? azurerm_resource_group.vmss[0].name : var.existingResourceGroup
  upgrade_policy_mode = "Manual"

  sku {
    name     = var.size
    capacity = var.instanceCount
  }

  storage_profile_image_reference {
    publisher = var.storage_profile_publisher
    offer     = var.storage_profile_offer
    sku       = var.storage_profile_sku
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"

  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = var.diskSizeGB
  }

  os_profile {
    computer_name_prefix = "${var.vmName}-os-profile"
    admin_username       = var.admin_user
    admin_password = "${var.isPassword ? var.admin_password : null}"
    custom_data = file("cloud-init.yaml")
}
  os_profile_linux_config {
    disable_password_authentication = "${var.isPassword ? false : true}"
    dynamic "ssh_keys" {
      for_each = local._isSSHKey
      content {
        key_data = "${var.publicKey}"
        path = "/home/${var.admin_user}/.ssh/authorized_keys"
      }
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = data.azurerm_subnet.tfresource.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary                                = true
    }
  }
}
