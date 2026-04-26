# ------------------------------------------------------------------------------
# Security Group — ALB
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group — managed by security_groups module"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project_name}-alb-sg"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = { for idx, rule in var.alb_ingress_rules : "${idx}-${rule.from_port}" => rule }

  security_group_id = aws_security_group.alb.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  for_each = { for idx, rule in var.alb_egress_rules : "${idx}-${rule.from_port}" => rule }

  security_group_id = aws_security_group.alb.id
  description       = each.value.description
  from_port         = each.value.from_port == 0 ? null : each.value.from_port
  to_port           = each.value.to_port == 0 ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
}

# ------------------------------------------------------------------------------
# Security Group — ECS Tasks
# ------------------------------------------------------------------------------

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "ECS tasks security group — inbound from ALB only"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project_name}-ecs-tasks-sg"
    Project = var.project_name
  }
}

# Ingress: each port in ecs_ingress_ports, source = ALB SG only
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  for_each = toset([for p in var.ecs_ingress_ports : tostring(p)])

  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "Allow port ${each.value} from ALB"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs" {
  for_each = { for idx, rule in var.ecs_egress_rules : "${idx}-${rule.from_port}" => rule }

  security_group_id = aws_security_group.ecs_tasks.id
  description       = each.value.description
  from_port         = each.value.from_port == 0 ? null : each.value.from_port
  to_port           = each.value.to_port == 0 ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
}
