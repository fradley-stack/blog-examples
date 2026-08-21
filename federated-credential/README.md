# An Azure DevOps service connection with no stored secret

A user-assigned managed identity with a federated credential, so an Azure Pipelines
service connection authenticates by presenting a short-lived token instead of a client
secret somebody has to keep renewing.

## What it creates

A resource group, a user-assigned managed identity, a federated identity credential
trusting one named service connection in one Azure DevOps project, and a Contributor
role assignment scoped to that resource group.

## Use it

Set your organisation, project, and the name you will give the service connection:

```bash
terraform init
terraform apply \
  -var="azdo_organization=your-org" \
  -var="azdo_project=Your-Project" \
  -var="service_connection_name=sc-azure-prod"
```

Then in Azure DevOps, go to **Project settings > Service connections > New service
connection > Azure Resource Manager**, choose **Managed identity**, and give it the
same name you passed above. Where you need the values by hand, they are the outputs:

```bash
terraform output service_principal_id   # Service Principal Id field
terraform output tenant_id              # Tenant Id field
terraform output subject_identifier     # what Azure DevOps will send
```

## The line that carries the security

```hcl
subject = "sc://${var.azdo_organization}/${var.azdo_project}/${var.service_connection_name}"
```

That claim decides who gets in, and Entra matches it **case-sensitively**. A project
name typed with the wrong capitalisation is the usual reason the first pipeline run
fails with `AADSTS700213`.

Because the subject pins the credential to one named connection, a production
connection and a pull-request connection should be two identities with different
rights. Then authorise named pipelines on each connection rather than ticking *grant
access permission to all pipelines*, or anything in the project inherits production.

## Already have connections using secrets?

Don't hand-convert them. Azure DevOps has a **Convert** button per connection, and
Microsoft publishes a [bulk conversion
script](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops)
that walks a whole project. Conversions are reversible for seven days.

## Find the secrets you still have

Every app registration in the tenant still carrying a password, soonest expiry first:

```bash
az ad app list --all -o json \
  --query "[?length(passwordCredentials)>\`0\`]" \
| jq -r '.[] | .displayName as $n | .appId as $a
         | .passwordCredentials[] | [$n, $a, .endDateTime] | @tsv' \
| sort -t "$(printf '\t')" -k3
```

And anything still pinned to the Azure DevOps issuer that retires on 1 July 2027:

```bash
az ad app list --all --query "[].appId" -o tsv | while read -r id; do
  az ad app federated-credential list --id "$id" -o tsv \
    --query "[?starts_with(issuer,'https://vstoken.dev.azure.com')].[name,issuer]" \
  | sed "s|^|$id  |"
done
```

Both are read-only, so they are safe to run against production.

Full write-up: https://www.fradley.org.uk/blog/delete-the-secret-dont-rotate-it.html
