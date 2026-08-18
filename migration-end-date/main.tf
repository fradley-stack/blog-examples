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

# The rule: a rehosted VM with no 'review_by' date on it. Start with effect = "audit"
# (flags, blocks nothing). Change to "deny" once the existing estate is tagged and you
# want new undated VMs refused outright.
resource "azurerm_policy_definition" "audit_review_by" {
  name         = "audit-vm-missing-review-by"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Audit virtual machines missing a review_by date"
  description  = "Every rehosted workload should carry the date its migration decision gets revisited."

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Compute/virtualMachines" },
        { field = "tags['review_by']", exists = "false" }
      ]
    }
    then = { effect = "audit" }
  })
}

# The assignment: switch that rule on for the subscription.
resource "azurerm_subscription_policy_assignment" "audit_review_by" {
  name                 = "audit-vm-missing-review-by"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.audit_review_by.id
  display_name         = "Audit virtual machines missing a review_by date"
}
