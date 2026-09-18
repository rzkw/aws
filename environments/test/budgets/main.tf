provider "aws" {
  region = var.aws_region
}

locals {
  budgets = {
    "monthly-budget" = {
      time_period_start = "2026-01-01_00:00"
      time_period_end   = "2087-06-15_00:00"
      notifications = [
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 50
          threshold_type      = "PERCENTAGE"
          notification_type   = "FORECASTED"
        },
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 80
          threshold_type      = "PERCENTAGE"
          notification_type   = "ACTUAL"
        },
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 90
          threshold_type      = "PERCENTAGE"
          notification_type   = "ACTUAL"
        },
      ]
    }
    "zero-spend" = {
      time_period_start = "2026-01-01_00:00"
      time_period_end   = "2087-06-15_00:00"
      notifications = [
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 0.01
          threshold_type      = "ABSOLUTE_VALUE"
          notification_type   = "ACTUAL"
        },
      ]
    }
  }
}

resource "aws_budgets_budget" "this" {
  for_each = local.budgets

  name              = each.key
  budget_type       = "COST"
  limit_amount      = "1"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = each.value.time_period_start
  time_period_end   = each.value.time_period_end

  dynamic "notification" {
    for_each = each.value.notifications

    content {
      comparison_operator        = notification.value.comparison_operator
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      notification_type          = notification.value.notification_type
      subscriber_email_addresses = var.budget_subscriber_emails
    }
  }
}