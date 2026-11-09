#!/usr/bin/env bash
# Find storage accounts where anonymous blob access is on, or was never set
# (older accounts; Microsoft treats a blank value the same as on).
# Requires: az login, and the resource-graph extension:
#   az extension add --name resource-graph

az graph query -q "Resources | where type =~ 'microsoft.storage/storageaccounts' | where tostring(properties.allowBlobPublicAccess) != 'false' | project name, resourceGroup, subscriptionId, publicAccess = properties.allowBlobPublicAccess"

# To close one down, set <account> and <rg> and run:
# az storage account update --name <account> --resource-group <rg> --allow-blob-public-access false
