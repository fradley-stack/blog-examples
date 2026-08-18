#!/usr/bin/env bash
# Which rehosted workloads are past the date somebody set for revisiting them.
# Requires: az login, and the resource-graph extension:
#   az extension add --name resource-graph

# 1. VMs whose review date has already passed.
az graph query -q "Resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend review_by = todatetime(tags['review_by'])
| where isnotnull(review_by) and review_by < now()
| project name, resourceGroup, review_by, owner = tags['owner']
| order by review_by asc"

# 2. VMs carrying no date at all, which is the bigger number in most estates.
az graph query -q "Resources
| where type =~ 'microsoft.compute/virtualmachines'
| where isnull(tags['review_by'])
| project name, resourceGroup, location"

# To set a date on one, run:
# az resource tag --ids <resource-id> --tags review_by=2027-03-31 migration=rehost --is-incremental
