# Put an internet-facing AI workload's model and data behind the perimeter.
# The Azure landing zone reference already denies public endpoints on these
# services in corp (the Deny-Public-Endpoints initiative); online doesn't.
# This assigns the same five built-ins to one online AI workload subscription.
# Full write-up: https://www.fradley.org.uk/blog/secure-ai-behind-your-perimeter.html

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

variable "subscription_id" {
  description = "The AI workload's subscription (vended under online), as a GUID."
}

variable "policy_effect" {
  description = "Audit first; switch to Deny once queries.sh comes back clean."
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "policy_effect must be Audit, Deny or Disabled."
  }
}

locals {
  perimeter_policies = {
    # Azure AI Services resources should restrict network access
    "ai-services-private" = "037eea7a-bd0a-46c5-9a66-03aea78705d3"
    # Azure AI Search services should disable public network access
    "ai-search-private" = "ee980b6d-0eca-4501-8d54-f6290fd512c3"
    # Storage accounts should disable public network access
    "storage-private" = "b2982f36-99f2-4db5-8eff-283140c09693"
    # Azure Cosmos DB should disable public network access
    "cosmos-private" = "797b37f7-06b8-444c-b1ad-fc62867f335a"
    # Azure Key Vault should disable public network access
    "key-vault-private" = "405c5871-3e91-4644-8a63-58e19d68ff5b"
  }
}

resource "azurerm_subscription_policy_assignment" "perimeter" {
  for_each = local.perimeter_policies

  name                 = "ai-perimeter-${each.key}"
  display_name         = "AI workload perimeter: ${each.key}"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.value}"

  parameters = jsonencode({
    effect = { value = var.policy_effect }
  })
}

output "assignments" {
  value = { for k, a in azurerm_subscription_policy_assignment.perimeter : k => a.id }
}
