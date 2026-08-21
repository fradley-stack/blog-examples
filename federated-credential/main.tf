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

# Change this to your repository, as owner/name.
variable "github_repository" {
  description = "The GitHub repository allowed to deploy, as owner/name."
  type        = string
  default     = "OWNER/REPO"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-federated-credential-demo"
  location = var.location
}

# The identity the pipeline becomes. It holds no password of any kind.
resource "azurerm_user_assigned_identity" "deploy" {
  name                = "id-github-deploy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# The trust. GitHub's token for this exact repo and branch is accepted as proof
# of identity, so there is no secret to store, rotate, or leak.
resource "azurerm_federated_identity_credential" "github_main" {
  name                = "github-main"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.deploy.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:ref:refs/heads/main"
}

# Scope the rights to the resource group, not the subscription.
resource "azurerm_role_assignment" "deploy" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy.principal_id
}

# The three values the workflow needs. None of them is a secret.
output "azure_client_id" {
  value = azurerm_user_assigned_identity.deploy.client_id
}

output "azure_tenant_id" {
  value = azurerm_user_assigned_identity.deploy.tenant_id
}
