#!/usr/bin/env bash
# The real perimeter of each AI workload: every Foundry / Azure OpenAI account's
# resource group, and the five services an agent's data lives in, with their
# public network setting and private endpoint count.
# Full write-up: https://www.fradley.org.uk/blog/secure-ai-behind-your-perimeter.html
#
# Requires: az login, and the resource-graph extension:
#   az extension add --name resource-graph
#
# Look for rows with publicAccess "enabled" and privateEndpoints 0. On storage,
# "enabled (default)" means the setting was never made, so the account firewall
# decides, and it allows all networks unless someone changed it.

az graph query --first 1000 -q "resources
  | where type =~ 'microsoft.cognitiveservices/accounts'
  | distinct subscriptionId, resourceGroup
  | join kind=inner (
      resources
      | where type in~ ('microsoft.cognitiveservices/accounts', 'microsoft.search/searchservices',
          'microsoft.storage/storageaccounts', 'microsoft.documentdb/databaseaccounts',
          'microsoft.keyvault/vaults')
      | extend pna = tolower(tostring(properties.publicNetworkAccess)),
          pe = array_length(properties.privateEndpointConnections)
    ) on subscriptionId, resourceGroup
  | join kind=leftouter (
      resourcecontainers
      | where type =~ 'microsoft.resources/subscriptions'
      | project subscriptionId,
          mg = tostring(properties.managementGroupAncestorsChain[0].displayName)
    ) on subscriptionId
  | project mg, resourceGroup, name, service = tostring(split(type, '/')[0]),
      publicAccess = iff(isempty(pna), 'enabled (default)', pna),
      privateEndpoints = coalesce(pe, 0)
  | order by mg asc, resourceGroup asc"
