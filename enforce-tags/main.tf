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

data "azurerm_subscription" "current" {}

# The rule: a resource group with no 'owner' tag. Start with effect = "audit" (flags,
# blocks nothing). Change to "deny" once you trust it to refuse untagged resources.
resource "azurerm_policy_definition" "audit_owner_tag" {
  name         = "audit-missing-owner-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit resource groups missing an owner tag"

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Resources/subscriptions/resourceGroups" },
        { field = "tags['owner']", exists = "false" }
      ]
    }
    then = { effect = "audit" }
  })
}

# The assignment: switch that rule on for the subscription.
resource "azurerm_subscription_policy_assignment" "audit_owner_tag" {
  name                 = "audit-missing-owner-tag"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.audit_owner_tag.id
  display_name         = "Audit resource groups missing an owner tag"
}
