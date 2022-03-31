terraform {
  backend "azurerm" {
    resource_group_name  = "terraform_state_backend"
    storage_account_name = "terraformstatefiles1"
    container_name       = "tfstates"
    key                  = "nginx_demo.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "nginx_demo" {
  name     = "nginx_demo"
  location = var.location
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "bastion_public_ip"
  resource_group_name = azurerm_resource_group.nginx_demo.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "vnet1_bastion_host"
  resource_group_name = azurerm_resource_group.nginx_demo.name
  location            = var.location

  ip_configuration {
    name                 = "config"
    subnet_id            = module.vnet.vnet_subnets[1]
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

module "vnet" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.nginx_demo.name
  subnet_prefixes     = ["10.0.0.0/24", "10.0.1.0/27"]
  subnet_names        = ["subnet1", "AzureBastionSubnet"]

  depends_on = [azurerm_resource_group.nginx_demo]
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "webservers" {
  resource_group_name           = azurerm_resource_group.nginx_demo.name
  source                        = "Azure/compute/azurerm"
  nb_instances                  = 2
  nb_public_ip                  = 0
  vm_size                       = "Standard_DS1_v2"
  vm_hostname                   = "web-server"
  vm_os_publisher               = "Canonical"
  vm_os_offer                   = "0001-com-ubuntu-server-focal"
  vm_os_sku                     = "20_04-lts-gen2"
  data_sa_type                  = "Standard_LRS"
  remote_port                   = "22"
  vnet_subnet_id                = module.vnet.vnet_subnets[0]
  custom_data                   = file("./cloud-inits/nginx_web_server.yaml")
  delete_os_disk_on_termination = true
  enable_ssh_key                = false
  admin_password                = random_password.password.result

  depends_on = [azurerm_resource_group.nginx_demo]
}
module "nginx" {
  resource_group_name           = azurerm_resource_group.nginx_demo.name
  source                        = "Azure/compute/azurerm"
  nb_instances                  = 1
  nb_public_ip                  = 1
  vm_hostname                   = "load-balancer-server"
  vm_os_publisher               = "Canonical"
  vm_os_offer                   = "0001-com-ubuntu-server-focal"
  vm_os_sku                     = "20_04-lts-gen2"
  data_sa_type                  = "Standard_LRS"
  remote_port                   = "80"
  vm_size                       = "Standard_D2s_v3"
  vnet_subnet_id                = module.vnet.vnet_subnets[0]
  public_ip_dns                 = ["nginxdemo"]
  custom_data                   = file("./cloud-inits/nginx_load_balancer.yaml")
  delete_os_disk_on_termination = true
  enable_ssh_key                = false
  admin_password                = random_password.password.result

  depends_on = [azurerm_resource_group.nginx_demo]
}

module "prometheus_grafana_server" {
  resource_group_name           = azurerm_resource_group.nginx_demo.name
  source                        = "Azure/compute/azurerm"
  nb_instances                  = 1
  nb_public_ip                  = 1
  vm_hostname                   = "prometheus-grafana-server"
  vm_os_publisher               = "Canonical"
  vm_os_offer                   = "0001-com-ubuntu-server-focal"
  vm_os_sku                     = "20_04-lts-gen2"
  data_sa_type                  = "Standard_LRS"
  remote_port                   = "3000"
  vm_size                       = "Standard_DS1_v2"
  vnet_subnet_id                = module.vnet.vnet_subnets[0]
  custom_data                   = file("./cloud-inits/prometheus_grafana_server.yaml")
  delete_os_disk_on_termination = true
  enable_ssh_key                = false
  admin_password                = random_password.password.result

  depends_on = [azurerm_resource_group.nginx_demo]
}