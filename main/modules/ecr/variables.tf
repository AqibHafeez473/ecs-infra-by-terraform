variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Must be MUTABLE or IMMUTABLE."
  }
}
