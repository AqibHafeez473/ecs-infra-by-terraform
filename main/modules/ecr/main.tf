resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}
