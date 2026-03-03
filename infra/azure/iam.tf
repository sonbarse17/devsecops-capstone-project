# -------------------------------------------------------------
# Azure Managed Identities
# -------------------------------------------------------------

# --- User Assigned Managed Identity for AKS ---
# This is used instead of hardcoded Service Principal secrets
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "devsecops-aks-identity"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name
}

# --- Role Assignment ---
# Assigning the 'AcrPull' role to the Managed Identity so the AKS cluster
# can securely pull images from an Azure Container Registry (if one existed)
# without needing docker login credentials.
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_subscription.current.id # Broad scope for demo, ideally limit to ACR scope
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}
