resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                 = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # deliberately no public_ip_address_id — LLD 3.1, reached only via Bastion
  }
}

# LLD 7 / 10.4 — Standard_B1s, no public IP, cloud-init bootstraps Ansible
resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                             = "Standard_B1s"
  admin_username                   = var.admin_username
  network_interface_ids             = [azurerm_network_interface.vm.id]
  disable_password_authentication    = true
  custom_data                        = var.cloud_init_rendered
  tags                                = var.tags

  identity {
    type = "SystemAssigned" # id-ops-vm-dev, LLD 4.3
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
