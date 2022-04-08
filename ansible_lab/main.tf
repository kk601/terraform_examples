terraform {
  backend "local" {
    
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

locals {
  project_name = "terraform-demo"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ansible_demo" {
  name     = local.project_name
  location = "westeurope"
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${local.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ansible_demo.location
  resource_group_name = azurerm_resource_group.ansible_demo.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${local.project_name}-subnet-0"
  resource_group_name  = azurerm_resource_group.ansible_demo.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "linux_vm_public_ip" {
  count               = var.linux_vm_count
  name                = "${local.project_name}-linux-public-ip-${count.index}"
  resource_group_name = azurerm_resource_group.ansible_demo.name
  location            = azurerm_resource_group.ansible_demo.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "windows_vm_public_ip" {
  count               = var.windows_vm_count
  name                = "${local.project_name}-windows-public-ip-${count.index}"
  resource_group_name = azurerm_resource_group.ansible_demo.name
  location            = azurerm_resource_group.ansible_demo.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "linux_vm_nic" {
  count               = var.linux_vm_count
  name                = "${local.project_name}-linux-nic-${count.index}"
  location            = azurerm_resource_group.ansible_demo.location
  resource_group_name = azurerm_resource_group.ansible_demo.name

  ip_configuration {
    name                          = "linux-nic-config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.linux_vm_public_ip[count.index].id
  }
}
resource "azurerm_network_interface" "windows_vm_nic" {
  count               = var.windows_vm_count
  name                = "${local.project_name}-windows-nic-${count.index}"
  location            = azurerm_resource_group.ansible_demo.location
  resource_group_name = azurerm_resource_group.ansible_demo.name

  ip_configuration {
    name                          = "windows-nic-config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.windows_vm_public_ip[count.index].id
  }
}

resource "azurerm_network_security_group" "linux-nsg" {
  name                = "${local.project_name}-linux-nic-nsg"
  location            = azurerm_resource_group.ansible_demo.location
  resource_group_name = azurerm_resource_group.ansible_demo.name

  security_rule {
    name                       = "Allow ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "windows-nsg" {
  name                = "${local.project_name}-windows-nic-nsg"
  location            = azurerm_resource_group.ansible_demo.location
  resource_group_name = azurerm_resource_group.ansible_demo.name

  security_rule {
    name                       = "Allow winrm"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "linux_nsg_vm_association" {
  count                     = var.linux_vm_count
  network_interface_id      = azurerm_network_interface.linux_vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.linux-nsg.id
}
resource "azurerm_network_interface_security_group_association" "windows_nsg_vm_association" {
  count                     = var.windows_vm_count
  network_interface_id      = azurerm_network_interface.windows_vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.windows-nsg.id
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  count               = var.linux_vm_count
  name                = "linux-vm-${count.index}"
  resource_group_name = azurerm_resource_group.ansible_demo.name
  location            = azurerm_resource_group.ansible_demo.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.linux_vm_nic[count.index].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "random_password" "windows_password" {
  length           = 16
  special          = true
  override_special = "!$%&*()-_=+[]{}<>:?"
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  count               = var.windows_vm_count
  name                = "windows-vm-${count.index}"
  resource_group_name = azurerm_resource_group.ansible_demo.name
  location            = azurerm_resource_group.ansible_demo.location
  size                = "Standard_D2s_v4"
  admin_username      = var.admin_username
  admin_password      = random_password.windows_password.result
  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_virtual_machine_extension" "run-windows-vm-extension" {
  count                = var.windows_vm_count
  name                 = "windows-vm-custom-script-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"

  settings = <<SETTINGS
    {
        "fileUris": [ 
          "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        ],
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
    }
SETTINGS
}

resource "local_file" "ansible_inventory_file" {
  content = templatefile("${path.module}/templates/inventory_template.tmpl", {
    admin_username     = var.admin_username,
    win_password     = "${random_password.windows_password.result}",
    linux_vms = zipmap(tolist(azurerm_linux_virtual_machine.linux_vm[*].name),tolist(azurerm_linux_virtual_machine.linux_vm[*].public_ip_address)),
    windows_vms = zipmap(tolist(azurerm_windows_virtual_machine.windows_vm[*].name),tolist(azurerm_windows_virtual_machine.windows_vm[*].public_ip_address))
  })
  filename = "${path.module}/inventory/hosts.ini"

  depends_on = [
    azurerm_linux_virtual_machine.linux_vm,
    azurerm_windows_virtual_machine.windows_vm,
    random_password.windows_password
  ]
}