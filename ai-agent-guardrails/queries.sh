#!/usr/bin/env bash
# Where is the AI already? Every Azure AI services account in the tenant, with
# the management group its subscription sits under and the two settings the
# guardrail policies check.
# Full write-up: https://www.fradley.org.uk/blog/ai-agents-in-the-landing-zone.html
#
# Anything under a sandbox or the tenant root, or with keyAuthOff empty/false
# and publicAccess Enabled, was built outside the landing zone's rules.

az graph query --first 1000 -q "resources
  | where type =~ 'microsoft.cognitiveservices/accounts'
  | join kind=leftouter (
      resourcecontainers
      | where type =~ 'microsoft.resources/subscriptions'
      | project subscriptionId, subName = name,
          mg = tostring(properties.managementGroupAncestorsChain[0].displayName)
    ) on subscriptionId
  | project name, kind, subName, mg,
      keyAuthOff = properties.disableLocalAuth,
      publicAccess = properties.publicNetworkAccess
  | order by mg asc"
