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

# Adopt a storage account that already exists (built in the portal) without
# touching it. Swap the id for a real resource in your subscription:
#   az storage account show --name <account> --resource-group <rg> --query id -o tsv
import {
  to = azurerm_storage_account.logs
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ops/providers/Microsoft.Storage/storageAccounts/stlogsprod"
}

# This block must describe the account exactly as it is today. Don't write it by
# hand: run `terraform plan -generate-config-out=generated.tf` and Terraform
# drafts it for you, then tidy it and move it here.
resource "azurerm_storage_account" "logs" {
  name                     = "stlogsprod"
  resource_group_name      = "rg-ops"
  location                 = "uksouth"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
