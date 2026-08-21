# A GitHub Actions pipeline that deploys to Azure with no stored secret

A user-assigned managed identity with a federated credential, so a GitHub Actions
workflow authenticates to Azure by presenting a short-lived token from GitHub instead
of a client secret you have to keep alive.

## What it creates

A resource group, a user-assigned managed identity, a federated identity credential
trusting one branch of one GitHub repository, and a Contributor role assignment scoped
to that resource group.

## Use it

Set your repository, then apply:

```bash
terraform init
terraform apply -var="github_repository=your-org/your-repo"
```

Take the two outputs plus your subscription ID and add them to the repository as
**variables**, not secrets, since none of them is one:

```bash
gh variable set AZURE_CLIENT_ID       --body "$(terraform output -raw azure_client_id)"
gh variable set AZURE_TENANT_ID       --body "$(terraform output -raw azure_tenant_id)"
gh variable set AZURE_SUBSCRIPTION_ID --body "$(az account show --query id -o tsv)"
```

Then in the workflow:

```yaml
permissions:
  id-token: write      # without this, GitHub issues no token and the login fails
  contents: read

steps:
  - uses: azure/login@v2
    with:
      client-id: ${{ vars.AZURE_CLIENT_ID }}
      tenant-id: ${{ vars.AZURE_TENANT_ID }}
      subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

## The line that carries the security

```hcl
subject = "repo:${var.github_repository}:ref:refs/heads/main"
```

That claim decides who gets in. Scoped to a branch, only `main` can use the identity.
Scope it to the whole repository and any fork or feature branch satisfies it too. Give
pull requests a separate credential whose rights stop short of production.

## Find the secrets you still have

Every app registration in the tenant still carrying a password, soonest expiry first:

```bash
az ad app list --all -o json \
  --query "[?length(passwordCredentials)>\`0\`]" \
| jq -r '.[] | .displayName as $n | .appId as $a
         | .passwordCredentials[] | [$n, $a, .endDateTime] | @tsv' \
| sort -t "$(printf '\t')" -k3
```

Read-only, so it is safe to run against production.

Full write-up: https://www.fradley.org.uk/blog/delete-the-secret-dont-rotate-it.html
