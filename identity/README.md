# Managed identity instead of a stored secret

A user-assigned managed identity granted read access to a storage account, so an app
authenticates as that identity with no password or connection string stored anywhere.

## What it creates

A resource group, a storage account, a user-assigned managed identity, and a role
assignment giving that identity Storage Blob Data Reader on the account.

## Use it

The storage account name has to be globally unique. Change it in `main.tf`, then:

```bash
terraform init
terraform apply
```

Attach the identity to your App Service, Function, or VM, and it can read blobs with no
key in your config. Azure issues and rotates the credential; your code never sees it.

Full write-up: https://www.fradley.org.uk/blog/identity-is-the-perimeter.html
