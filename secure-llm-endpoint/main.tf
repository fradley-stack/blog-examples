# An Azure OpenAI endpoint a stolen key cannot open: key auth off, public
# network access off, Entra ID + managed identity only, private endpoint in.
# Full write-up: https://www.fradley.org.uk/blog/llm-endpoints-new-public-storage.html

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

variable "name" {
  description = "Short name used in resource names; also the custom subdomain, so it must be globally unique."
  default     = "myapp-llm-demo"
}

variable "location" {
  default = "uksouth"
}

resource "azurerm_resource_group" "ai" {
  name     = "rg-${var.name}"
  location = var.location
}

# --- Network for the private endpoint ---------------------------------------

resource "azurerm_virtual_network" "ai" {
  name                = "vnet-${var.name}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  address_space       = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.ai.name
  virtual_network_name = azurerm_virtual_network.ai.name
  address_prefixes     = ["10.10.0.0/27"]
}

# --- The LLM endpoint, production shape -------------------------------------

resource "azurerm_cognitive_account" "llm" {
  name                  = "oai-${var.name}"
  resource_group_name   = azurerm_resource_group.ai.name
  location              = azurerm_resource_group.ai.location
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "oai-${var.name}"

  # The two settings that matter. Key auth off means a leaked connection
  # string is just a string; callers need an Entra ID token instead.
  local_auth_enabled            = false
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }
}

# A model deployment on the account. Version is omitted on purpose, so the
# platform default (current version) is used.
resource "azurerm_cognitive_deployment" "gpt" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.llm.id

  model {
    format = "OpenAI"
    name   = "gpt-4o"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 10
  }
}

# --- Private endpoint + DNS, so the endpoint resolves inside the VNet only --

resource "azurerm_private_dns_zone" "openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.ai.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = "link-${var.name}"
  resource_group_name   = azurerm_resource_group.ai.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.ai.id
}

resource "azurerm_private_endpoint" "llm" {
  name                = "pe-oai-${var.name}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-oai-${var.name}"
    private_connection_resource_id = azurerm_cognitive_account.llm.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-oai-${var.name}"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }
}

# --- The caller: a managed identity with the inference role, no secrets -----

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.name}-app"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
}

resource "azurerm_role_assignment" "app_inference" {
  scope                = azurerm_cognitive_account.llm.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

output "endpoint" {
  value = azurerm_cognitive_account.llm.endpoint
}
