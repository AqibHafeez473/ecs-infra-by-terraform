# ------------------------------------------------------------------------------
# General
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "myapp"
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

# ------------------------------------------------------------------------------
# ECS
# ------------------------------------------------------------------------------

variable "task_cpu" {
  description = "ECS task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 7
}

# ------------------------------------------------------------------------------
# ECR
# ------------------------------------------------------------------------------

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}

# ------------------------------------------------------------------------------
# GitHub Actions OIDC
# ------------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# ------------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------------

variable "alb_ingress_rules" {
  description = "Ingress rules for ALB security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "alb_egress_rules" {
  description = "Egress rules for ALB security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "ecs_ingress_ports" {
  description = "Ports ECS tasks accept from ALB"
  type        = list(number)
  default     = []
}

variable "ecs_egress_rules" {
  description = "Egress rules for ECS tasks security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}
