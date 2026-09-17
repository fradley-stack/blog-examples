#!/usr/bin/env bash
# Turn sixty days of VNet flow logs into a candidate ruleset, and find the NSG rules
# that nothing used.
#
# Read-only: nothing here changes anything.
#
#   WORKSPACE=$(terraform output -raw workspace_id) bash queries.sh
#
# Needs two CLI extensions, once:
#   az extension add --name resource-graph
#   az extension add --name log-analytics
#
# Full write-up: https://www.fradley.org.uk/blog/firewall-rules-nobody-can-explain.html

set -euo pipefail

: "${WORKSPACE:?Set WORKSPACE to the Log Analytics workspace ID (a GUID)}"
DAYS="${DAYS:-60}"

la() {
  az monitor log-analytics query --workspace "$WORKSPACE" --analytics-query "$1" "${@:2}"
}

echo "=============================================================="
echo " 1. Allow rules, and how many carry no description"
echo "    The gap between the first two columns is access nobody"
echo "    wrote a reason down for."
echo "=============================================================="
az graph query --first 1000 -o table -q "
resources
| where type =~ 'microsoft.network/networksecuritygroups'
| mv-expand rule = properties.securityRules
| where tostring(rule.properties.access) == 'Allow'
| summarize allowRules = count(),
            noReason   = countif(isempty(tostring(rule.properties.description))),
            anySource  = countif(tostring(rule.properties.sourceAddressPrefix) in ('*', 'Internet', '0.0.0.0/0'))
  by subscriptionId
| order by allowRules desc"

echo
echo "=============================================================="
echo " 2. Candidate ruleset: private conversations seen in ${DAYS} days"
echo "    One row per source, destination, port and protocol. Each"
echo "    row needs a person who can say what it is for."
echo "=============================================================="
la "
NTANetAnalytics
| where TimeGenerated > ago(${DAYS}d)
| where SubType =~ 'FlowLog'
| where isnotempty(SrcIp) and isnotempty(DestIp)
| where AllowedInFlows + AllowedOutFlows > 0
| summarize flows     = sum(AllowedInFlows + AllowedOutFlows),
            firstSeen = min(FlowStartTime),
            lastSeen  = max(FlowEndTime),
            viaRules  = make_set(AclRule, 10)
  by SrcSubnet, SrcIp, DestSubnet, DestIp, DestPort, L4Protocol
| order by DestSubnet asc, DestPort asc, flows desc" -o table

echo
echo "=============================================================="
echo " 3. Internet-bound destinations"
echo "    Public addresses arrive packed in DestPublicIps rather than"
echo "    DestIp. MaliciousFlow rows matched Microsoft threat intel."
echo "=============================================================="
la "
NTANetAnalytics
| where TimeGenerated > ago(${DAYS}d)
| where SubType =~ 'FlowLog'
| where FlowType in ('ExternalPublic', 'MaliciousFlow') and isnotempty(DestPublicIps)
| mv-expand entry = split(DestPublicIps, ' ')
| extend DestPublicIp = tostring(split(tostring(entry), '|')[0])
| where isnotempty(DestPublicIp)
| summarize flows    = sum(AllowedOutFlows + DeniedOutFlows),
            lastSeen = max(FlowEndTime),
            types    = make_set(FlowType)
  by SrcSubnet, SrcVm, DestPublicIp, DestPort, L4Protocol
| order by flows desc" -o table

echo
echo "=============================================================="
echo " 4. Hits per existing rule"
echo "    Allowed and denied flow counts, and when each rule last"
echo "    matched anything."
echo "=============================================================="
la "
NTANetAnalytics
| where TimeGenerated > ago(${DAYS}d)
| where SubType =~ 'FlowLog' and isnotempty(AclRule)
| summarize allowed = sum(AllowedInFlows + AllowedOutFlows),
            denied  = sum(DeniedInFlows + DeniedOutFlows),
            lastHit = max(FlowEndTime)
  by AclGroup, AclRule
| order by AclGroup asc, allowed asc" -o table

echo
echo "=============================================================="
echo " 5. NSG rules that matched no traffic in ${DAYS} days"
echo "    Start the review here. Deny these at a higher priority"
echo "    before deleting anything, and wait out a month-end."
echo "=============================================================="
# Resource Graph returns 1,000 rows per page. For a bigger estate, page with
# --skip-token or scope the query with --subscriptions.
all_rules=$(mktemp)
hit_rules=$(mktemp)
trap 'rm -f "$all_rules" "$hit_rules"' EXIT

az graph query --first 1000 -o tsv --query "data[].key" -q "
resources
| where type =~ 'microsoft.network/networksecuritygroups'
| mv-expand rule = properties.securityRules
| project key = tolower(strcat(subscriptionId, '/', resourceGroup, '/', name, '/', tostring(rule.name)))" \
  | tr -d '\r' | sort -u > "$all_rules"

# Older flow records prefix user rules with UserRule_; strip it so the names match.
la "
NTANetAnalytics
| where TimeGenerated > ago(${DAYS}d)
| where SubType =~ 'FlowLog' and isnotempty(AclRule)
| distinct key = tolower(strcat(AclGroup, '/', replace_regex(AclRule, @'^UserRule_', '')))" \
  -o tsv --query "[].key" | tr -d '\r' | sort -u > "$hit_rules"

comm -23 "$all_rules" "$hit_rules"
echo
echo "   Count: $(comm -23 "$all_rules" "$hit_rules" | wc -l | tr -d ' ') of $(wc -l < "$all_rules" | tr -d ' ') rules"
