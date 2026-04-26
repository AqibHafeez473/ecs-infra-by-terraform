variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN — scopes the ECR push policy"
  type        = string
}
