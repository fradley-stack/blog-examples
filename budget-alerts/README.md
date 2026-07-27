# Budget alerts as code

An email when your Azure spend crosses 80% of a monthly budget, so you hear about it
from an alert rather than the invoice.

## What it creates

A subscription-level monthly budget with a notification at 80% of the amount.

## Use it

1. Edit `main.tf`: set `amount` to your monthly ceiling, `contact_emails` to your
   address, and `start_date` to the first of an upcoming month.
2. Apply it:

```bash
terraform init
terraform apply
```

`threshold = 80` fires the email at 80% of the amount, so you get a nudge rather than a
shock. Add another `notification` block for a 100% or forecast alert.

Full write-up: https://www.fradley.org.uk/blog/budget-alerts-as-code.html
