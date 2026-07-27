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

# Point this at the resource group you want to protect.
data "azurerm_resource_group" "prod" {
  name = "prod-rg"
}

# CanNotDelete: reads and changes still work, deletion is refused until the lock is removed.
# Use lock_level = "ReadOnly" to freeze changes as well.
resource "azurerm_management_lock" "no_delete" {
  name       = "no-delete"
  scope      = data.azurerm_resource_group.prod.id
  lock_level = "CanNotDelete"
  notes      = "Protects production from accidental deletion."
}
