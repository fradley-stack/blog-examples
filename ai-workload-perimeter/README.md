# AI workload perimeter

An AI workload is more than its model endpoint. A Foundry agent keeps its data
in your own Storage, AI Search and Cosmos DB accounts, with secrets in Key
Vault, so the perimeter has to cover all five services.

In the Azure landing zone reference, the corp management group already denies
public endpoints on all five. Online doesn't, and online is where CAF puts
internet-facing AI. This example assigns the same five built-in policies to an
online AI workload's subscription, so only its front end can be public.

## Find what's exposed now

`queries.sh` finds every resource group holding a Foundry or Azure OpenAI
account and lists the five services in it, with their public network setting
and private endpoint count.

```bash
bash queries.sh
```

## Run it

```bash
terraform init
terraform plan -var subscription_id=<ai-workload-subscription-guid>
terraform apply -var subscription_id=<ai-workload-subscription-guid>
```

The policies start in `Audit`. Once the query comes back clean, apply again
with `-var policy_effect=Deny`.

## Not covered here

- Egress. These policies close the way in. Agent traffic out goes through
  virtual network injection and the hub firewall, which has to be chosen when
  the Foundry resource is created; it can't be added afterwards. The write-up
  has the list.
- Corp workloads. If the subscription sits under corp in a standard Azure
  landing zone, the Deny-Public-Endpoints initiative already covers this. Check
  it hasn't been switched to DoNotEnforce or exempted before adding a second copy.
- Keys. Key access on the AI account is a separate policy, in
  [ai-agent-guardrails](../ai-agent-guardrails/).

Full write-up: https://www.fradley.org.uk/blog/secure-ai-behind-your-perimeter.html
