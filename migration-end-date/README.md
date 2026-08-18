# A written end date for a rehosted workload

Lift-and-shift is a legitimate move with a written end date and a liability without one.
This puts the date somewhere the estate can answer for itself, instead of in a migration
plan nobody opens once the programme closes.

## Move 1: find the undated workloads (Azure CLI)

`queries.sh` runs two Resource Graph queries: VMs whose `review_by` date has already
passed, and VMs carrying no date at all. The second list is the longer one in most estates.

```bash
bash queries.sh
```

(Run `az extension add --name resource-graph` first if you don't have it.)

## Move 2: stop new ones appearing undated (Terraform)

`main.tf` defines and assigns a policy that audits virtual machines with no `review_by`
tag. Start with the `audit` effect. Once the existing estate is tagged, change `effect`
to `deny` so an undated VM can't be created at all.

```bash
terraform init
terraform apply
```

The tag itself is three lines wherever the workload is defined:

```hcl
tags = {
  owner     = "payments"
  migration = "rehost"
  review_by = "2027-03-31"
}
```

Full write-up: https://www.fradley.org.uk/blog/lift-and-shift-end-date.html
