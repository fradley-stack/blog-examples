# Find public-facing storage

A one-query check for storage accounts where anonymous blob access is on, or
was never set. Either way, a container set to public in that account can be
read by anyone on the internet without signing in.

## Run it (Azure CLI)

```bash
az graph query -q "Resources | where type =~ 'microsoft.storage/storageaccounts' | where tostring(properties.allowBlobPublicAccess) != 'false' | project name, resourceGroup, subscriptionId, publicAccess = properties.allowBlobPublicAccess"
```

A blank `publicAccess` means an older account that never had the setting made.
Microsoft's remediation guidance treats that the same as on.

Check nothing reads from the account anonymously on purpose, then close it down:

```bash
az storage account update --name <account> --resource-group <rg> --allow-blob-public-access false
```

A static website's `$web` container stays public either way.

Full write-up: https://www.fradley.org.uk/blog/find-public-storage.html
