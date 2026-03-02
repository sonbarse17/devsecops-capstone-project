provider "azurerm" {
  features {}
  # Insecure: Missing proper tenant configuration
}

resource "azurerm_resource_group" "insecure_rg" {
  name     = "insecure-resources"
  location = "East US"
}

# Insecure AKS Cluster
# tfsec:ignore:azure-container-limit-authorized-ips
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
    # Secure: Added network policy
    network_policy = "calico"
  }

  api_server_access_profile {
    # Secure: Authorized IP ranges restricted
    authorized_ip_ranges = ["192.168.1.0/24"]
  }

  # Secure: Role Based Access Control is enabled
  role_based_access_control_enabled = true

  oms_agent {
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/mygroup/providers/microsoft.operationalinsights/workspaces/myworkspace"
  }
}
