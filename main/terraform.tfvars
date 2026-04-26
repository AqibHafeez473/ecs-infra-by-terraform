aws_region   = "us-east-1"
project_name = "myapp"

# ECS
task_cpu           = 256
task_memory        = 512
desired_count      = 1
log_retention_days = 7
container_port     = 80

# ECR
ecr_image_tag_mutability = "MUTABLE"

# GitHub Actions OIDC — update before applying
github_org  = "your-github-org"
github_repo = "your-github-repo"

# ------------------------------------------------------------------------------
# Security Groups — edit ports/CIDRs here, no code changes needed
# ------------------------------------------------------------------------------

alb_ingress_rules = [
  {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  # Uncomment to add HTTPS
  # {
  #   description = "Allow HTTPS from internet"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
]

alb_egress_rules = [
  {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# Ports ECS tasks accept — must match container_port
ecs_ingress_ports = [80]

ecs_egress_rules = [
  {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
