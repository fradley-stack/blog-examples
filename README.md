<div align="center">
  <img src="assets/cloud.svg" width="72" alt="pixel cloud" />
  <h1>blog-examples</h1>
  <p><em>Small, runnable Azure guardrails &mdash; the code behind <a href="https://www.fradley.org.uk">fradley.org.uk</a></em></p>
</div>

[![License: MIT](https://img.shields.io/badge/license-MIT-5df2b3.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-ready-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Azure](https://img.shields.io/badge/Microsoft-Azure-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Read the blog](https://img.shields.io/badge/read-fradley.org.uk-5df2b3)](https://www.fradley.org.uk)

```console
$ az login
$ terraform apply
# guardrails, shipped.
```

Each folder here is one idea from the blog you can apply this week: a few lines of Terraform or Azure CLI, a short README, and a link to the full write-up. Built for people getting into Azure and Infrastructure as Code.

Nothing here is clever. That's rather the point. The guardrails that save you rarely are.

## What's inside

| Example | What it does | Read the story |
|---|---|---|
| [budget-alerts](budget-alerts/) | Email alert at 80% of a monthly Azure budget | [Never get surprised by the Azure bill](https://www.fradley.org.uk/blog/budget-alerts-as-code.html) |
| [resource-locks](resource-locks/) | Stop someone deleting a production resource group | [Stop someone deleting prod](https://www.fradley.org.uk/blog/resource-locks-prevent-deletion.html) |
| [allowed-locations](allowed-locations/) | Restrict Azure to the regions you permit | [Keep Azure in the right regions](https://www.fradley.org.uk/blog/allowed-locations-policy.html) |
| [enforce-tags](enforce-tags/) | Find untagged resources, then enforce tags as code | [Untagged Azure resources](https://www.fradley.org.uk/blog/enforce-azure-tags-as-code.html) |
| [find-public-storage](find-public-storage/) | Find storage accounts open to the public | [Find your public-facing storage](https://www.fradley.org.uk/blog/find-public-storage.html) |
| [identity](identity/) | A managed identity instead of a stored secret | [Identity is your security perimeter](https://www.fradley.org.uk/blog/identity-is-the-perimeter.html) |

## Who this is for

- You've been clicking around the Azure portal and want to stop.
- You want a governance or reliability guardrail in place today, not after the next incident.
- You learn best from something small you can run, break, and rebuild.

New to this? Start with [budget-alerts](budget-alerts/) or [resource-locks](resource-locks/). Five minutes each, and useful the moment they're applied.

## Running the examples

You'll need:

- An Azure subscription and the [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login`.
- [Terraform](https://developer.hashicorp.com/terraform/install) for the `.tf` examples.

Each Terraform example is self-contained. From inside a folder:

```bash
terraform init
terraform plan    # see what it will do
terraform apply   # do it
```

The CLI examples run as-is once you're signed in.

## A word of sense

These are teaching examples, kept deliberately small. Read them before you run them, swap the placeholder names and regions for your own, and run `terraform plan` before you apply anywhere you'd miss.

## Found a bug, or want one explaining?

Open an [issue](https://github.com/fradley-stack/blog-examples/issues). If an example could be clearer, or there's a guardrail you'd like written up, that's useful feedback, and it often becomes the next post.

## About

I'm Dom Fradley, an Azure architect. I publish a short, practical Azure piece most weeks at [fradley.org.uk](https://www.fradley.org.uk), and I'm on [LinkedIn](https://www.linkedin.com/in/domfradley/).

## License

[MIT](LICENSE). Use these however helps.
