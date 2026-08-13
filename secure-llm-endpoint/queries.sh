#!/usr/bin/env bash
# Find every AI account in the estate still running demo-day defaults.
# Full write-up: https://www.fradley.org.uk/blog/llm-endpoints-new-public-storage.html

# Inventory: every cognitive services account, with the two settings that matter.
# localAuthDisabled empty or false + publicAccess Enabled = demo-day defaults.
az graph query -q "resources
  | where type == 'microsoft.cognitiveservices/accounts'
  | project name, kind, resourceGroup,
      localAuthDisabled = properties.disableLocalAuth,
      publicAccess = properties.publicNetworkAccess"

# Close one down: turn key auth off on a specific account (callers then need
# an Entra ID token; make sure nothing still depends on the key first).
# az resource update --ids <account-resource-id> --set properties.disableLocalAuth=true
