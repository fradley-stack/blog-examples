terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "app" {
  name     = "app-rg"
  location = "uksouth"
}

# Storage account name must be globally unique: 3-24 lowercase alphanumeric chars.
resource "azurerm_storage_account" "data" {
  name                     = "appdata0example01" # change to something unique
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# A user-assigned managed identity: nothing to store, nothing to leak.
resource "azurerm_user_assigned_identity" "app" {
  name                = "app-identity"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
}

# Grant the identity exactly the access it needs, and nothing more.
resource "azurerm_role_assignment" "app_reads_storage" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
