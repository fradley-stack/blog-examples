# The platform team's side of landing AI agents in an existing Azure landing
# zone: AI guardrail policies on the landing zones management group, and a
# per-agent token quota at the AI gateway (API Management).
# Full write-up: https://www.fradley.org.uk/blog/ai-agents-in-the-landing-zone.html

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

# --- Policy on the landing zones management group -------------------------------

variable "landing_zones_mg_name" {
  description = "Name (ID) of the landing zones management group, parent of corp and online."
  default     = "landingzones"
}

variable "policy_effect" {
  description = "Audit first; switch to Deny once the inventory query comes back clean."
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.policy_effect)
    error_message = "policy_effect must be Audit, Deny or Disabled."
  }
}

data "azurerm_management_group" "landing_zones" {
  name = var.landing_zones_mg_name
}

locals {
  ai_policies = {
    # Azure AI Services resources should have key access disabled (disable local authentication)
    "ai-keys-off" = "/providers/Microsoft.Authorization/policyDefinitions/71ef260a-8f18-47b7-abcb-62d0673d94dc"
    # Azure AI Services resources should restrict network access
    "ai-private-only" = "/providers/Microsoft.Authorization/policyDefinitions/037eea7a-bd0a-46c5-9a66-03aea78705d3"
  }
}

resource "azurerm_management_group_policy_assignment" "ai" {
  for_each = local.ai_policies

  name                 = each.key
  display_name         = "AI agents: ${each.key}"
  management_group_id  = data.azurerm_management_group.landing_zones.id
  policy_definition_id = each.value

  parameters = jsonencode({
    effect = { value = var.policy_effect }
  })
}

# --- The AI gateway: one product, key and token quota per agent -------------------

variable "apim_name" {
  description = "Existing API Management instance acting as the AI gateway (connectivity subscription)."
}

variable "apim_resource_group" {
  description = "Resource group of the API Management instance."
}

variable "llm_api_name" {
  description = "Name of the model API already imported into API Management."
}

variable "agents" {
  description = "One entry per agent, taken from its landing request."
  type = map(object({
    owner             = string
    cost_centre       = string
    monthly_tokens    = number
    tokens_per_minute = number
  }))
  default = {
    "invoice-triage" = {
      owner             = "finance-ops@example.com"
      cost_centre       = "FIN-001"
      monthly_tokens    = 50000000
      tokens_per_minute = 20000
    }
  }
}

data "azurerm_api_management" "gateway" {
  name                = var.apim_name
  resource_group_name = var.apim_resource_group
}

resource "azurerm_api_management_product" "agent" {
  for_each = var.agents

  product_id            = "agent-${each.key}"
  display_name          = "Agent: ${each.key}"
  description           = "Owner ${each.value.owner}, cost centre ${each.value.cost_centre}"
  api_management_name   = data.azurerm_api_management.gateway.name
  resource_group_name   = data.azurerm_api_management.gateway.resource_group_name
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "agent" {
  for_each = var.agents

  product_id          = azurerm_api_management_product.agent[each.key].product_id
  api_name            = var.llm_api_name
  api_management_name = data.azurerm_api_management.gateway.name
  resource_group_name = data.azurerm_api_management.gateway.resource_group_name
}

# The agent's own key. Its subscription ID is the counter the quota uses.
resource "azurerm_api_management_subscription" "agent" {
  for_each = var.agents

  display_name        = "agent-${each.key}"
  product_id          = azurerm_api_management_product.agent[each.key].id
  api_management_name = data.azurerm_api_management.gateway.name
  resource_group_name = data.azurerm_api_management.gateway.resource_group_name
  state               = "active"
}

# 403 once the month's tokens are used, 429 when the per-minute rate is
# exceeded. Azure budgets only alert on Azure OpenAI; this is the hard stop.
resource "azurerm_api_management_product_policy" "agent" {
  for_each = var.agents

  product_id          = azurerm_api_management_product.agent[each.key].product_id
  api_management_name = data.azurerm_api_management.gateway.name
  resource_group_name = data.azurerm_api_management.gateway.resource_group_name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <llm-token-limit
            counter-key="@(context.Subscription.Id)"
            tokens-per-minute="${each.value.tokens_per_minute}"
            token-quota="${each.value.monthly_tokens}"
            token-quota-period="Monthly"
            estimate-prompt-tokens="false"
            remaining-quota-tokens-header-name="x-agent-quota-remaining" />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}

output "agent_keys" {
  description = "Hand each agent its own key; a shared key means a shared quota."
  value       = { for k, s in azurerm_api_management_subscription.agent : k => s.primary_key }
  sensitive   = true
}
