provider "azurerm" {
  features {}
  # Insecure: Missing proper tenant configuration
}

resource "azurerm_resource_group" "insecure_rg" {
  name     = "insecure-resources"
  location = "East US"
}

# Insecure AKS Cluster
resource "azurerm_kubernetes_cluster" "insecure_aks" {
  name                = "insecure-aks"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name
  dns_prefix          = "insecureaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    # Insecure: No network policy applied (e.g., Calico or Azure)
  }

  api_server_access_profile {
    # Insecure: No authorized IP ranges, open to the internet
  }

  # Insecure: Role Based Access Control is disabled
  role_based_access_control_enabled = false
}
