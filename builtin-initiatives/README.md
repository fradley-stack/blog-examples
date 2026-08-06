# Switch on a built-in policy initiative

Microsoft ships just over 5,000 ready-written policy definitions and about 270
grouped initiatives with every Azure subscription, including sets mapped
control-by-control to ISO 27001, NIST, PCI DSS, CIS and the UK OFFICIAL
controls. This example assigns one of them in audit mode: everything gets
reported, nothing gets blocked, and the compliance page starts filling in on
its own.

Full write-up: [Azure Policy out of the box: 5,000 guardrails you already own](https://www.fradley.org.uk/blog/azure-policy-out-of-the-box.html)

## Run it

```bash
terraform init
terraform plan    # see the assignment it will create
terraform apply
```

Or without Terraform, `queries.sh` has the equivalent `az` one-liner, plus a
query that lists every Regulatory Compliance initiative in the catalogue so you
can pick the one your sector answers to.

## Read the results

Results appear within about half an hour in **Portal → Policy → Compliance**,
or from the command line:

```bash
az policy state summarize \
  --query "policyAssignments[].{assignment:policyAssignmentId, nonCompliant:results.nonCompliantResources}" \
  -o table
```

Expect the first number to be ugly. An ugly number you can see beats a
clean-looking estate nobody has measured.

## Notes

- Audit mode blocks nothing, so this is safe to run on a real subscription.
  Graduating individual rules to `deny` is a per-rule decision for later.
- Initiatives that include remediation effects (`deployIfNotExists`, `modify`)
  also need an `identity` block on the assignment before they can act.
- Assigning a framework's initiative does not make you certified against it.
  It automates the technically checkable slice and gives you live evidence;
  auditors still want your processes and paperwork.
