terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

# A monthly budget with an email alert at 80% of the amount.
resource "azurerm_consumption_budget_subscription" "monthly_cap" {
  name            = "monthly-cap"
  subscription_id = data.azurerm_subscription.current.id
  amount          = 500 # your monthly ceiling, in your billing currency
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-08-01T00:00:00Z" # must be the first of a month, in the future
  }

  notification {
    enabled        = true
    threshold      = 80 # percent of amount that triggers the alert
    operator       = "GreaterThan"
    contact_emails = ["you@example.com"]
  }
}
