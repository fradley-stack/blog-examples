# Resource locks: stop someone deleting prod

A lock that makes Azure refuse to delete anything in a resource group until the lock is
deliberately removed.

## The one-liner (Azure CLI)

```bash
az lock create --name no-delete --lock-type CanNotDelete --resource-group prod-rg
```

`CanNotDelete` still allows reads and changes; it only blocks deletion. Use `ReadOnly`
to freeze changes as well.

## The repeatable version (Terraform)

`main.tf` applies the same lock so it lives in a repo. Point the `prod` data source at
your resource group, then:

```bash
terraform init
terraform apply
```

Full write-up: https://www.fradley.org.uk/blog/resource-locks-prevent-deletion.html
