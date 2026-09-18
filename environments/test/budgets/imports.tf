import {
  to = aws_budgets_budget.this["monthly-budget"]
  id = "${var.account_id}:monthly-budget"
}

import {
  to = aws_budgets_budget.this["zero-spend"]
  id = "${var.account_id}:zero-spend"
}