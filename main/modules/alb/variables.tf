variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy ALB into"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "alb_sg_id" {
  description = "ALB security group ID — provided by security_groups module"
  type        = string
}
