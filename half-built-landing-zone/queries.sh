#!/usr/bin/env bash
# Size the gaps in a half-built landing zone before you decide what to fix first.
#
# Three counts. Each one turns a vague gap into a number you can sequence.
# Read-only: nothing here changes anything.
#
#   bash queries.sh
#
# Needs the Resource Graph extension for queries 2 and 3:
#   az extension add --name resource-graph
#
# Full write-up: https://www.fradley.org.uk/blog/half-built-landing-zone.html

set -euo pipefail

echo "=============================================================="
echo " 1. Role assignments held directly by users"
echo "    Every row is access no code knows about. This is the"
echo "    retrofit, and it grows every week you work elsewhere."
echo "=============================================================="
az role assignment list --all --include-inherited \
  --query "[?principalType=='User'].{user:principalName, role:roleDefinitionName, scope:scope}" \
  -o table

echo
echo "   Count only:"
az role assignment list --all --include-inherited \
  --query "length([?principalType=='User'])" -o tsv

echo
echo "=============================================================="
echo " 2. Resources with no cost centre tag, by subscription"
echo "    Cost Management cannot attribute spend it had no tag for"
echo "    at the time the usage was recorded. Waiting costs history."
echo "=============================================================="
az graph query -q "
resources
| where isnull(tags['cost_centre']) or tags['cost_centre'] == ''
| summarize untagged = count() by subscriptionId, type
| order by untagged desc
" --first 50 -o table

echo
echo "=============================================================="
echo " 3. Resource groups your platform Terraform does not manage"
echo "    Compare this list against your state file. Anything here"
echo "    and not in state is hand-built, or drift on top of code."
echo "=============================================================="
az graph query -q "
resourcecontainers
| where type == 'microsoft.resources/subscriptions/resourcegroups'
| project subscriptionId, name, managedBy = tostring(properties.managedBy)
| order by subscriptionId asc, name asc
" --first 200 -o table

echo
echo "   Then, in the platform repo:"
echo "     terraform state list | sed -n 's/.*resource_group.*/&/p'"
echo "   Anything above that is missing below is not under code."
