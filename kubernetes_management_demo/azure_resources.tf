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

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "microservices-deployment-demo" {
  name     = var.project_name
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.microservices-deployment-demo.location
  resource_group_name = azurerm_resource_group.microservices-deployment-demo.name
  dns_prefix          = "${var.project_name}-dns"
  node_resource_group = "node-rg-${azurerm_resource_group.microservices-deployment-demo.name}"

  default_node_pool {
    name                = "default"
    vm_size             = "standard_ds2_v2"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 2
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "local_sensitive_file" "kubeconfig" {
    content  = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
    filename = pathexpand("~/.kube/kubernetes_management_demo_kubeconfig")
}