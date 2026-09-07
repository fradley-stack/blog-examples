# Identity, done the way it stops costing you more every week.
#
# Two moves, both of which the article argues you make first:
#   1. Role assignments live in code, target a group, and sit at a scope a new
#      spoke inherits. Nobody gets a direct assignment on a resource group.
#   2. Standing owner rights for humans become *eligible* rather than active,
#      so the access exists but somebody has to ask for it and say why.
#
# Full write-up: https://www.fradley.org.uk/blog/half-built-landing-zone.html

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "management_group_name" {
  description = "Management group the platform team's standing read access hangs off."
  type        = string
  default     = "mg-platform"
}

data "azurerm_management_group" "platform" {
  name = var.management_group_name
}

data "azurerm_subscription" "workload" {}

data "azurerm_role_definition" "reader" {
  name = "Reader"
}

data "azurerm_role_definition" "owner" {
  name = "Owner"
}

# The group is the unit of access. People join and leave it; the assignment
# below never changes, and nothing has to be unpicked when somebody moves team.
resource "azuread_group" "platform_engineers" {
  display_name     = "sg-platform-engineers"
  security_enabled = true
}

# Move 1: standing access is read-only, granted to the group, at management
# group scope. Every subscription created underneath inherits it, so a new
# spoke never needs its own assignment.
resource "azurerm_role_assignment" "platform_read" {
  scope              = data.azurerm_management_group.platform.id
  role_definition_id = data.azurerm_role_definition.reader.id
  principal_id       = azuread_group.platform_engineers.object_id
}

# Move 2: the write access nobody should hold at 3pm on a Tuesday. Eligible,
# not active. Activating it requires a justification and shows up in the audit
# log, and the eligibility itself expires.
resource "azurerm_pim_eligible_role_assignment" "platform_break_glass" {
  scope              = data.azurerm_subscription.workload.id
  role_definition_id = "${data.azurerm_subscription.workload.id}${data.azurerm_role_definition.owner.id}"
  principal_id       = azuread_group.platform_engineers.object_id

  schedule {
    expiration {
      duration_days = 365
    }
  }

  justification = "Platform team break-glass, activated per incident"
}
