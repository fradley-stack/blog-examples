#!/usr/bin/env bash
# Find storage accounts that allow public blob access, across the whole subscription.
# Requires: az login, and the resource-graph extension:
#   az extension add --name resource-graph

az graph query -q "Resources | where type =~ 'microsoft.storage/storageaccounts' | where properties.allowBlobPublicAccess == true | project name, resourceGroup, location"

# To close one down, set <account> and <rg> and run:
# az storage account update --name <account> --resource-group <rg> --allow-blob-public-access false
