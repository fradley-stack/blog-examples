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

# Look the initiative up by display name, so the code carries no magic GUIDs.
# Swap the name for any set on the built-in list, e.g. "ISO/IEC 27001 2022"
# or "UK OFFICIAL and UK NHS":
# https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-initiatives
data "azurerm_policy_set_definition" "cis" {
  display_name = "CIS Azure Foundations v3.0.0"
}

# Audit-only assignment: everything is reported, nothing is blocked.
# Initiatives that include remediation effects (deployIfNotExists / modify)
# also need an identity block before they can act on resources.
resource "azurerm_subscription_policy_assignment" "cis_audit" {
  name                 = "cis-v3-audit"
  display_name         = "CIS Azure Foundations v3.0.0 (audit)"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_set_definition.cis.id
}
