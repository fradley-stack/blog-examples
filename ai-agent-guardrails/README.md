# AI agent guardrails

The platform team's side of putting AI agents into a landing zone you already
have. Two built-in policies go on the landing zones management group (key
access off, network access restricted), and each agent gets its own API
Management product and key with a monthly token quota at the AI gateway.

## Find what's already there

`queries.sh` lists every Azure AI services account in the tenant with the
management group it sits under. Run it before assigning anything, so you know
what the policies will flag.

```bash
bash queries.sh
```

## Run it

You need the landing zones management group, plus an API Management instance
with your model API already imported (the AI gateway). Add one entry to the
`agents` map per agent, from its landing request.

```bash
terraform init
terraform plan -var apim_name=apim-ai-gateway -var apim_resource_group=rg-connectivity-ai \
  -var llm_api_name=azure-openai
terraform apply
```

The policies start in `Audit`. Once the query comes back clean, apply again
with `-var policy_effect=Deny`.

`terraform output -json agent_keys` gives each agent its key. Hand them out one
per agent; a shared key means a shared quota.

## Not covered here

- "Foundry model deployments should only use approved models" is the third
  policy from the write-up. It needs your approved publishers or model IDs as
  parameters, so add it once that list is agreed.
- The quota counts prompt and completion tokens only. Tool calls bill on
  their own meters.
- Each gateway keeps its own count, so a multi-region APIM doesn't share one
  total.

Full write-up: https://www.fradley.org.uk/blog/ai-agents-in-the-landing-zone.html
