terraform {
  backend "s3" {
    bucket = "devsecops-terraform-state-bucket"
    key    = "azure/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "insecure_rg" {
  name     = "devsecops-resources"
  location = "East US"
}

# -------------------------------------------------------------
# Virtual Network & Segmented Subnets
# -------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "devsecops-vnet"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name
  address_space       = ["10.1.0.0/16"]
}

# --- 1. Public Subnet ---
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.insecure_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# --- 2. App Subnet (EKS/AKS) ---
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.insecure_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

# --- 3. Data Subnet (Databases) ---
resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.insecure_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

# -------------------------------------------------------------
# Network Security Groups (NSGs)
# -------------------------------------------------------------

# Public NSG
resource "azurerm_network_security_group" "public_nsg" {
  name                = "public-nsg"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public_assoc" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# App NSG
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name

  security_rule {
    name                       = "AllowFromPublicTier"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.1.1.0/24" # Public Subnet
    destination_address_prefix = "*"
  }
  # Block other inbound, Azure defaults allow VNet inbound
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Data NSG
resource "azurerm_network_security_group" "data_nsg" {
  name                = "data-nsg"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name

  security_rule {
    name                       = "AllowFromAppTier"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.1.2.0/24" # App Subnet
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "data_assoc" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

# -------------------------------------------------------------
# Secure AKS Cluster
# -------------------------------------------------------------
# tfsec:ignore:azure-container-limit-authorized-ips
resource "azurerm_kubernetes_cluster" "secure_aks" {
  name                = "devsecops-aks"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name
  dns_prefix          = "devsecopsaks"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure" # Better integration with NSGs
    network_policy = "calico"
  }

  api_server_access_profile {
    authorized_ip_ranges = ["192.168.1.0/24"]
  }

  role_based_access_control_enabled = true

  oms_agent {
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/mygroup/providers/microsoft.operationalinsights/workspaces/myworkspace"
  }
}
