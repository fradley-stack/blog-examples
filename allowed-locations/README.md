# Allowed locations policy

Assigns Azure's built-in "Allowed locations" policy, so resources can only be created in
the regions you permit.

## Use it

Edit `listOfAllowedLocations` in `main.tf` to your regions, then:

```bash
terraform init
terraform apply
```

From then on, any attempt to deploy outside those regions is refused. The long policy id
is the built-in "Allowed locations" definition. Confirm it in your own tenant with:

```bash
az policy definition list --query "[?displayName=='Allowed locations'].name" -o tsv
```

Full write-up: https://www.fradley.org.uk/blog/allowed-locations-policy.html
