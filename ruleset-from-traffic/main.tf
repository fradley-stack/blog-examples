# Record what crosses a legacy network before you migrate its rules.
#
# One VNet flow log on the legacy virtual network, processed by Traffic Analytics
# into a Log Analytics workspace. Leave it running for at least sixty days, and
# through a month-end, before you trust the output of queries.sh.
#
# NSG flow logs can no longer be created and retire on 30 September 2027, so the
# target here is the virtual network itself.
#
# Full write-up: https://www.fradley.org.uk/blog/firewall-rules-nobody-can-explain.html

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Region of the legacy VNet. The storage account has to be in the same one."
  type        = string
  default     = "uksouth"
}

variable "legacy_vnet_name" {
  description = "The virtual network whose traffic you want to observe."
  type        = string
}

variable "legacy_vnet_resource_group" {
  description = "Resource group that holds the legacy VNet."
  type        = string
}

variable "flowlog_storage_account_name" {
  description = "Globally unique, 3-24 lowercase letters and digits."
  type        = string
}

data "azurerm_virtual_network" "legacy" {
  name                = var.legacy_vnet_name
  resource_group_name = var.legacy_vnet_resource_group
}

# Azure creates one Network Watcher per region, in NetworkWatcherRG, the first time
# a VNet lands there. If yours was deleted or lives elsewhere, change these two names.
data "azurerm_network_watcher" "this" {
  name                = "NetworkWatcher_${var.location}"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_resource_group" "discovery" {
  name     = "rg-migration-discovery"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "discovery" {
  name                = "log-migration-discovery"
  location            = azurerm_resource_group.discovery.location
  resource_group_name = azurerm_resource_group.discovery.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# Standard tier, same region as the VNet, and no lifecycle rules of its own: the flow
# log's retention policy overwrites any that exist.
resource "azurerm_storage_account" "flowlogs" {
  name                     = var.flowlog_storage_account_name
  location                 = azurerm_resource_group.discovery.location
  resource_group_name      = azurerm_resource_group.discovery.name
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"

  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_network_watcher_flow_log" "legacy" {
  name                 = "fl-${var.legacy_vnet_name}"
  network_watcher_name = data.azurerm_network_watcher.this.name
  resource_group_name  = data.azurerm_network_watcher.this.resource_group_name

  target_resource_id = data.azurerm_virtual_network.legacy.id
  storage_account_id = azurerm_storage_account.flowlogs.id
  enabled            = true

  retention_policy {
    enabled = true
    days    = 90
  }

  # 60 minutes is enough for discovery and costs less per GB than 10.
  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.discovery.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.discovery.location
    workspace_resource_id = azurerm_log_analytics_workspace.discovery.id
    interval_in_minutes   = 60
  }
}

output "workspace_id" {
  description = "Pass this to queries.sh as WORKSPACE."
  value       = azurerm_log_analytics_workspace.discovery.workspace_id
}
