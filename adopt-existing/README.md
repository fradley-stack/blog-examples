# Adopt an existing resource into Terraform

Put Terraform in charge of a resource that was built by hand, in place, without
rebuilding or touching it. This is the mechanism that turns a ClickOps estate
into a managed one with no big-bang rewrite.

## The flow

1. Get the resource id of something that already exists:

```bash
az storage account show --name <account> --resource-group <rg> --query id -o tsv
```

2. Put the id in the `import` block in `main.tf`, then let Terraform draft the
matching configuration for you:

```bash
terraform init
terraform plan -generate-config-out=generated.tf
```

3. Tidy the generated block into `main.tf` (or keep `generated.tf`), then run
the acceptance test:

```bash
terraform plan
```

## The acceptance test

You are done when the plan says:

```text
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

That line means the code is a faithful description of what's running and
nothing will be modified. `terraform apply` then records the resource in state,
and from that point changes to it go through code review instead of the portal.

If the plan shows changes, the config doesn't match reality yet. Fix the config
to match the resource, never the other way round, until the diff is zero.

Full write-up: https://www.fradley.org.uk/blog/clickops-to-code.html
