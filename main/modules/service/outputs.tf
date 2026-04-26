output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.app.id
}
