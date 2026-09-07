# Sizing and sequencing a half-built landing zone

The foundations are real: hub-and-spoke, a subscription structure, Terraform for the
platform, a pipeline, some Azure Policy. Four things are half done, workloads keep
landing while you fix them, and you have five engineers and a roadmap that will not pause.

The article argues the ordering variable is not risk. It is how much each gap costs to
close after another quarter of delivery. These two files cover the measuring and the
first move.

## Step 1: size the gaps (Azure CLI)

`queries.sh` runs three read-only counts, one per gap you can actually measure:

- role assignments held directly by users, at every scope
- resources carrying no cost centre tag, grouped by subscription
- resource groups to diff against your platform Terraform state

```bash
az extension add --name resource-graph   # once
bash queries.sh
```

The first number is the one that grows while you decide. Run it before you design anything.

## Step 2: fix identity first (Terraform)

`main.tf` shows the shape the article argues for. Standing access is read-only, granted
to a group, at management group scope, so every new spoke inherits it. The write access
becomes a PIM eligible assignment instead of a permanent one, so it has to be activated
with a justification and the eligibility expires on its own.

```bash
terraform init
terraform apply
```

Privileged Identity Management is a licensed feature. Check what the tenant already holds
before you design around it.

Remove the existing direct assignments last, with the output of query 1 in front of you.
It is the only step here that can break somebody's Tuesday.

Full write-up: https://www.fradley.org.uk/blog/half-built-landing-zone.html
