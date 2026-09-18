import {
  to = aws_budgets_budget.monthly
  id = "${var.account_id}:monthly-budget"
}

import {
  to = aws_budgets_budget.zero_spend
  id = "${var.account_id}:zero-spend"
}
