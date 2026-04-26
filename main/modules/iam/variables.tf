variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN for IAM policy scoping"
  type        = string
}
