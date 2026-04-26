# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "alb_dns_name" {
  description = "Application Load Balancer URL — open in browser to access the app"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL — use to push Docker images"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.service.service_name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = module.ecs.task_definition_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = module.iam.ecs_task_role_arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions role ARN — use as role-to-assume in workflow"
  value       = module.oidc.github_actions_role_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.ecs.log_group_name
}

output "vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}
