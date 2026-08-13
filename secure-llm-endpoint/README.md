# Secure LLM endpoint

An Azure OpenAI endpoint in its production shape: key auth off, public network
access off, callers use a managed identity with the inference role, and the
endpoint only resolves through a private endpoint inside the VNet. A stolen
key opens nothing, because there are no keys.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

`var.name` becomes the account's custom subdomain, so pick something globally
unique. The model deployment uses `gpt-4o` at the platform's current default
version; swap the model block for whatever your subscription has quota for.

## Find the accounts you already have

`queries.sh` runs one Resource Graph query that lists every AI account in the
estate and the two settings that matter. Anything with local auth enabled and
public access on is carrying demo-day defaults in production.

Full write-up: https://www.fradley.org.uk/blog/llm-endpoints-new-public-storage.html
