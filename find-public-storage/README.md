# Find public-facing storage

A one-query check for storage accounts open to public blob access, the sort of thing a
mis-set container turns into a data leak.

## Run it (Azure CLI)

```bash
az graph query -q "Resources | where type =~ 'microsoft.storage/storageaccounts' | where properties.allowBlobPublicAccess == true | project name, resourceGroup, location"
```

Anything returned is an account where a container could be made public. Close one down:

```bash
az storage account update --name <account> --resource-group <rg> --allow-blob-public-access false
```

`queries.sh` has both commands ready to run. On a schedule, a nasty surprise becomes a
routine check.

Full write-up: https://www.fradley.org.uk/blog/find-public-storage.html
