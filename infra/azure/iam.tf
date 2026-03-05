
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "devsecops-aks-identity"
  location            = azurerm_resource_group.insecure_rg.location
  resource_group_name = azurerm_resource_group.insecure_rg.name
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}
