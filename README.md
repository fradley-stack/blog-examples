# Azure IaC Starters

Small, runnable examples of the Azure governance and reliability guardrails I write
about on [fradley.org.uk](https://www.fradley.org.uk). Each folder is one idea you can
apply this week: a few lines of Terraform or Azure CLI, a short README, and a link to
the full write-up.

Built for people getting into Azure and Infrastructure as Code. Nothing here is
clever. That's the point — the guardrails that save you rarely are.

## Examples

| Folder | What it does | Write-up |
|---|---|---|
| [budget-alerts](budget-alerts/) | Email alert at 80% of a monthly Azure budget | [Never get surprised by the Azure bill](https://www.fradley.org.uk/blog/budget-alerts-as-code.html) |
| [resource-locks](resource-locks/) | Stop someone deleting a production resource group | [Stop someone deleting prod](https://www.fradley.org.uk/blog/resource-locks-prevent-deletion.html) |
| [allowed-locations](allowed-locations/) | Restrict Azure to the regions you permit | [Keep Azure in the right regions](https://www.fradley.org.uk/blog/allowed-locations-policy.html) |
| [enforce-tags](enforce-tags/) | Find untagged resources, then enforce tags as code | [Untagged Azure resources](https://www.fradley.org.uk/blog/enforce-azure-tags-as-code.html) |
| [find-public-storage](find-public-storage/) | Find storage accounts open to the public | [Find your public-facing storage](https://www.fradley.org.uk/blog/find-public-storage.html) |

## Running these

You'll need:

- An Azure subscription and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login`.
- [Terraform](https://developer.hashicorp.com/terraform/install) for the `.tf` examples.

Each Terraform example is self-contained. From inside a folder:

```bash
terraform init
terraform plan     # see what it will do
terraform apply    # do it
```

The CLI examples run as-is once you're signed in with `az login`.

## A word of sense

These are teaching examples, kept deliberately small. Read them before you run them,
change the placeholder names and regions to your own, and run `terraform plan` before
you apply in an environment you care about.

## More

- Full write-ups, roughly one a week: [fradley.org.uk](https://www.fradley.org.uk)
- I'm Dom Fradley, an Azure architect. Say hello on [LinkedIn](https://www.linkedin.com/in/domfradley/).
