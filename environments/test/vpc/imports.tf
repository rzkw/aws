import {
  to = aws_vpc.vpc-1
  id = var.vpc_id
}

import {
  to = aws_subnet.dev
  id = var.subnet_id
}

import {
  to = aws_route_table.rt-1
  id = var.route_table_id
}
