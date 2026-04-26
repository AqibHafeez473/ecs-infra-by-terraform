variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

# ------------------------------------------------------------------------------
# ALB Security Group Rules
# ------------------------------------------------------------------------------

variable "alb_ingress_rules" {
  description = "List of ingress rules for the ALB security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "alb_egress_rules" {
  description = "List of egress rules for the ALB security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ------------------------------------------------------------------------------
# ECS Tasks Security Group Rules
# ------------------------------------------------------------------------------

variable "ecs_ingress_ports" {
  description = "List of ports ECS tasks accept inbound (from ALB only)"
  type        = list(number)
  default     = [80]
}

variable "ecs_egress_rules" {
  description = "List of egress rules for the ECS tasks security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
