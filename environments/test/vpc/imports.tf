import {
  to = aws_vpc.this
  id = var.vpc_id
}

import {
  to = aws_subnet.this
  id = var.subnet_id
}

import {
  to = aws_route_table.this
  id = var.route_table_id
}