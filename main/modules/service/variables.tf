variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "task_definition_arn" {
  description = "ECS task definition ARN"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "ecs_tasks_sg_id" {
  description = "ECS tasks security group ID — provided by security_groups module"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN — service depends on this"
  type        = string
}
