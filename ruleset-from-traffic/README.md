# Rebuilding a legacy ruleset from observed traffic

A migration plan usually copies the legacy network rules into the new landing zone as
they are, because nobody left can say which ones are safe to drop. The article argues
for rebuilding them from what crosses the network, and giving a flow a rule
only when somebody can say what it is for.

These two files record the traffic and then read it back.

## Step 1: start recording (Terraform)

`main.tf` puts a VNet flow log on the legacy virtual network, with Traffic Analytics
feeding a Log Analytics workspace at the 60-minute interval.

```bash
terraform init
terraform apply \
  -var legacy_vnet_name=vnet-legacy \
  -var legacy_vnet_resource_group=rg-legacy-network \
  -var flowlog_storage_account_name=stflowlogsdiscovery01
```

NSG flow logs can no longer be created and retire on 30 September 2027, so this
targets the VNet. The storage account must sit in the same region as the VNet.

Then wait. Sixty days is the minimum, and the window has to include a month-end.
Anything that runs quarterly or annually won't show up, so ask finance and operations
what runs on a schedule and write it down.

Collection costs $0.50 per GB after 5 GB free per subscription each month, and Traffic
Analytics processing $2.30 per GB at the 60-minute interval (UK South retail prices,
September 2026). Workspace ingestion and blob storage cost extra.

## Step 2: read it back (Azure CLI)

`queries.sh` runs five read-only queries:

1. Allow rules per subscription, and how many have no description
2. The candidate ruleset: every private conversation seen, with first and last seen
3. Internet-bound destinations, including any Traffic Analytics flagged as malicious
4. Allowed and denied hits per existing NSG rule
5. The NSG rules that matched no traffic at all in the window

```bash
az extension add --name resource-graph   # once
az extension add --name log-analytics    # once
WORKSPACE=$(terraform output -raw workspace_id) bash queries.sh
```

Output 2 is a candidate list that still needs approval. Some of that traffic is a job
retrying against a server switched off years ago, and some of it could be an attacker.
Review each row against what the workload is supposed to talk to, with your security
lead, and end the new ruleset in deny.

## Step 3: deny before you delete

For the rules in output 5, and for flows nobody claims, add an explicit deny at a
higher priority instead of deleting anything. Removing one rule undoes it.

```hcl
resource "azurerm_network_security_rule" "scream_test" {
  name                        = "deny-unclaimed-sql-from-app"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_address_prefix       = "10.10.2.0/24"
  source_port_range           = "*"
  destination_address_prefix  = "10.10.5.0/24"
  destination_port_range      = "1433"
  description                 = "Scream test for rule allow-sql-legacy. Owner: platform team. Remove after month-end if nobody calls."
  resource_group_name         = "rg-legacy-network"
  network_security_group_name = "nsg-legacy-data"
}
```

Leave it through the next month-end and watch for denied flows in the same workspace.

VNet flow logs don't record traffic for some platform services, including App Service,
Azure Functions, Logic Apps and SQL Managed Instance. Read those flows from the other end, or from
the service's own diagnostics.

Full write-up: https://www.fradley.org.uk/blog/firewall-rules-nobody-can-explain.html
