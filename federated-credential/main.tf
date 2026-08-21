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

# These three must match Azure DevOps exactly, including case. The subject claim
# is built from them, and a mismatched project name is the usual reason the first
# pipeline run fails.
variable "azdo_organization" {
  description = "Azure DevOps organisation name, as it appears in dev.azure.com/<org>."
  type        = string
  default     = "your-org"
}

variable "azdo_project" {
  description = "Azure DevOps project name."
  type        = string
  default     = "Your-Project"
}

variable "service_connection_name" {
  description = "The name you will give the service connection in Azure DevOps."
  type        = string
  default     = "sc-azure-prod"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-federated-credential-demo"
  location = var.location
}

# The identity the pipeline becomes. It holds no password of any kind.
resource "azurerm_user_assigned_identity" "deploy" {
  name                = "id-azdo-deploy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# The trust. Azure DevOps presents a token naming this exact service connection,
# and Entra accepts it as proof of identity. Nothing to store, rotate, or leak.
resource "azurerm_federated_identity_credential" "azdo" {
  name                      = "azdo-${var.service_connection_name}"
  user_assigned_identity_id = azurerm_user_assigned_identity.deploy.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  subject                   = "sc://${var.azdo_organization}/${var.azdo_project}/${var.service_connection_name}"
}

# Scope the rights to a resource group, not the whole subscription.
resource "azurerm_role_assignment" "deploy" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy.principal_id
}

# Paste these into the service connection dialog in Azure DevOps.
output "service_principal_id" {
  description = "Client ID of the managed identity. Goes in the Service Principal Id field."
  value       = azurerm_user_assigned_identity.deploy.client_id
}

output "tenant_id" {
  description = "Tenant ID. Goes in the Tenant Id field."
  value       = azurerm_user_assigned_identity.deploy.tenant_id
}

output "subject_identifier" {
  description = "What Azure DevOps will send. Must match the federated credential exactly."
  value       = azurerm_federated_identity_credential.azdo.subject
}

# ---------------------------------------------------------------------------
# If part of the estate builds on GitHub Actions instead, the model is the same
# and only the claims change. Add a second credential on the same identity:
#
# resource "azurerm_federated_identity_credential" "github_main" {
#   name                      = "github-main"
#   user_assigned_identity_id = azurerm_user_assigned_identity.deploy.id
#   audience                  = ["api://AzureADTokenExchange"]
#   issuer                    = "https://token.actions.githubusercontent.com"
#   subject                   = "repo:your-org/your-repo:ref:refs/heads/main"
# }
# ---------------------------------------------------------------------------
