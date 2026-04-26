terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# Data Sources — Default VPC & Public Subnets
# ------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  subnet_ids = slice(data.aws_subnets.public.ids, 0, 2)
}

# ------------------------------------------------------------------------------
# Module: Security Groups
# ------------------------------------------------------------------------------

module "security_groups" {
  source = "./modules/security_groups"

  project_name      = var.project_name
  vpc_id            = data.aws_vpc.default.id
  alb_ingress_rules = var.alb_ingress_rules
  alb_egress_rules  = var.alb_egress_rules
  ecs_ingress_ports = var.ecs_ingress_ports
  ecs_egress_rules  = var.ecs_egress_rules
}

# ------------------------------------------------------------------------------
# Module: ECR
# ------------------------------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  project_name             = var.project_name
  ecr_image_tag_mutability = var.ecr_image_tag_mutability
}

# ------------------------------------------------------------------------------
# Module: IAM  — ECS roles only
# ------------------------------------------------------------------------------

module "iam" {
  source = "./modules/iam"

  project_name       = var.project_name
  ecr_repository_arn = module.ecr.repository_arn
}

# ------------------------------------------------------------------------------
# Module: OIDC  — GitHub Actions OIDC provider + ECR push role
# ------------------------------------------------------------------------------

module "oidc" {
  source = "./modules/oidc"

  project_name       = var.project_name
  github_org         = var.github_org
  github_repo        = var.github_repo
  ecr_repository_arn = module.ecr.repository_arn
}

# ------------------------------------------------------------------------------
# Module: ALB
# ------------------------------------------------------------------------------

module "alb" {
  source = "./modules/alb"

  project_name   = var.project_name
  vpc_id         = data.aws_vpc.default.id
  subnet_ids     = local.subnet_ids
  container_port = var.container_port
  alb_sg_id      = module.security_groups.alb_sg_id
}

# ------------------------------------------------------------------------------
# Module: ECS
# ------------------------------------------------------------------------------

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  aws_region         = var.aws_region
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  container_port     = var.container_port
  log_retention_days = var.log_retention_days
  ecr_repository_url = module.ecr.repository_url
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
}

# ------------------------------------------------------------------------------
# Module: Service
# ------------------------------------------------------------------------------

module "service" {
  source = "./modules/service"

  project_name        = var.project_name
  vpc_id              = data.aws_vpc.default.id
  subnet_ids          = local.subnet_ids
  container_port      = var.container_port
  desired_count       = var.desired_count
  cluster_id          = module.ecs.cluster_id
  task_definition_arn = module.ecs.task_definition_arn
  target_group_arn    = module.alb.target_group_arn
  ecs_tasks_sg_id     = module.security_groups.ecs_tasks_sg_id
  alb_listener_arn    = module.alb.listener_arn
}
