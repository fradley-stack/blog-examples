# Enforce tags as code

Two moves: find every untagged resource today, then stop new ones appearing.

## Move 1: find untagged resources (Azure CLI)

```bash
az graph query -q "Resources | where isnull(tags.owner) | project name, type, resourceGroup, location"
```

(Run `az extension add --name resource-graph` first if you don't have it.)

## Move 2: enforce it (Terraform)

`main.tf` defines and assigns a policy that audits resource groups with no `owner` tag.
Start with the `audit` effect. Once you trust it, change `effect` to `deny` so untagged
resources can't be created at all.

```bash
terraform init
terraform apply
```

Full write-up: https://www.fradley.org.uk/blog/enforce-azure-tags-as-code.html
