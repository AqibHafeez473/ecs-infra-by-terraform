#!/usr/bin/env bash
# ==============================================================================
#  deploy.sh — Full Infrastructure Deploy Script
#  Usage:
#    ./deploy.sh            # deploy everything
#    ./deploy.sh destroy    # tear down everything (reverse order)
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Colors & Formatting
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$SCRIPT_DIR/bootstrap"
MAIN_DIR="$SCRIPT_DIR/main"
BACKEND_FILE="$MAIN_DIR/backend.tf"
LOG_FILE="$SCRIPT_DIR/deploy.log"

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------
log()    { echo -e "${BOLD}[$(date '+%H:%M:%S')]${RESET} $*" | tee -a "$LOG_FILE"; }
info()   { echo -e "${BLUE}${BOLD}  ℹ  $*${RESET}" | tee -a "$LOG_FILE"; }
success(){ echo -e "${GREEN}${BOLD}  ✔  $*${RESET}" | tee -a "$LOG_FILE"; }
warn()   { echo -e "${YELLOW}${BOLD}  ⚠  $*${RESET}" | tee -a "$LOG_FILE"; }
error()  { echo -e "${RED}${BOLD}  ✘  $*${RESET}" | tee -a "$LOG_FILE"; }
divider(){ echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" | tee -a "$LOG_FILE"; }
header() {
  divider
  echo -e "${CYAN}${BOLD}  $*${RESET}" | tee -a "$LOG_FILE"
  divider
}

# ------------------------------------------------------------------------------
# Preflight Checks
# ------------------------------------------------------------------------------
preflight_checks() {
  header "Preflight Checks"

  local missing=0

  for cmd in terraform aws; do
    if command -v "$cmd" &>/dev/null; then
      success "$cmd found  →  $(command -v $cmd)"
    else
      error "$cmd not found — please install it first"
      missing=$((missing + 1))
    fi
  done

  # AWS credentials check
  if aws sts get-caller-identity &>/dev/null; then
    local account region identity
    account=$(aws sts get-caller-identity --query Account --output text)
    region=$(aws configure get region 2>/dev/null || echo "not set")
    identity=$(aws sts get-caller-identity --query Arn --output text)
    success "AWS credentials valid"
    info "Account : $account"
    info "Region  : $region"
    info "Identity: $identity"
  else
    error "AWS credentials invalid or not configured"
    error "Run: aws configure"
    missing=$((missing + 1))
  fi

  # Directories exist
  for dir in "$BOOTSTRAP_DIR" "$MAIN_DIR"; do
    if [[ -d "$dir" ]]; then
      success "Directory found: $dir"
    else
      error "Directory missing: $dir"
      missing=$((missing + 1))
    fi
  done

  if [[ $missing -gt 0 ]]; then
    error "Preflight failed — fix $missing issue(s) above and retry"
    exit 1
  fi

  success "All preflight checks passed"
}

# ------------------------------------------------------------------------------
# Step 1 — Bootstrap (S3 + DynamoDB)
# ------------------------------------------------------------------------------
run_bootstrap() {
  header "Step 1/3 — Bootstrap  (S3 + DynamoDB remote state)"

  cd "$BOOTSTRAP_DIR"

  info "terraform init ..."
  terraform init -upgrade -input=false >> "$LOG_FILE" 2>&1
  success "Init complete"

  # Check if bucket already exists
  local project_name aws_region account_id bucket_name
  project_name=$(grep 'project_name' terraform.tfvars | awk -F'"' '{print $2}')
  aws_region=$(grep 'aws_region' terraform.tfvars | awk -F'"' '{print $2}')
  account_id=$(aws sts get-caller-identity --query Account --output text)
  bucket_name="${project_name}-tf-state-${account_id}"

  if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    warn "S3 bucket '$bucket_name' already exists — skipping bootstrap apply"
  else
    info "terraform apply ..."
    terraform apply -auto-approve -input=false >> "$LOG_FILE" 2>&1
    success "Bootstrap apply complete"
  fi

  # Capture outputs
  BUCKET_NAME=$(terraform output -raw s3_bucket_name)
  DYNAMO_TABLE=$(terraform output -raw dynamodb_table_name)

  success "S3 bucket     : $BUCKET_NAME"
  success "DynamoDB table: $DYNAMO_TABLE"

  cd "$SCRIPT_DIR"
}

# ------------------------------------------------------------------------------
# Step 2 — Patch backend.tf with real values
# ------------------------------------------------------------------------------
patch_backend() {
  header "Step 2/3 — Patching backend.tf"

  if grep -q "<BUCKET_NAME>" "$BACKEND_FILE"; then
    info "Replacing placeholder values in backend.tf ..."

    sed -i.bak \
      -e "s|<BUCKET_NAME>|${BUCKET_NAME}|g" \
      -e "s|<DYNAMODB_TABLE_NAME>|${DYNAMO_TABLE}|g" \
      "$BACKEND_FILE"

    success "backend.tf updated"
    info "  bucket         = \"$BUCKET_NAME\""
    info "  dynamodb_table = \"$DYNAMO_TABLE\""
  else
    warn "backend.tf already patched — skipping"
    # Still read the values for logging
    BUCKET_NAME=$(grep 'bucket' "$BACKEND_FILE" | grep -v '#' | awk -F'"' '{print $2}')
    DYNAMO_TABLE=$(grep 'dynamodb_table' "$BACKEND_FILE" | grep -v '#' | awk -F'"' '{print $2}')
    info "  bucket         = \"$BUCKET_NAME\""
    info "  dynamodb_table = \"$DYNAMO_TABLE\""
  fi
}

# ------------------------------------------------------------------------------
# Step 3 — Main Infrastructure
# ------------------------------------------------------------------------------
run_main() {
  header "Step 3/3 — Main Infrastructure"

  cd "$MAIN_DIR"

  # Check for un-edited tfvars placeholders
  if grep -q "your-github-org\|your-github-repo" terraform.tfvars; then
    warn "Placeholder values detected in main/terraform.tfvars:"
    warn "  github_org  = \"your-github-org\""
    warn "  github_repo = \"your-github-repo\""
    echo ""
    read -r -p "$(echo -e ${YELLOW}${BOLD}'  Do you want to continue anyway? [y/N]: '${RESET})" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      info "Edit main/terraform.tfvars and re-run ./deploy.sh"
      exit 0
    fi
  fi

  info "terraform init (with backend migration) ..."
  terraform init -upgrade -migrate-state -input=false -force-copy >> "$LOG_FILE" 2>&1
  success "Init complete"

  info "terraform validate ..."
  if terraform validate >> "$LOG_FILE" 2>&1; then
    success "Validate passed"
  else
    error "Validate failed — check deploy.log for details"
    exit 1
  fi

  info "terraform plan ..."
  terraform plan -out=tfplan -input=false >> "$LOG_FILE" 2>&1
  success "Plan complete"

  echo ""
  read -r -p "$(echo -e ${YELLOW}${BOLD}'  Apply this plan? [y/N]: '${RESET})" confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    info "Deploy cancelled — run ./deploy.sh again when ready"
    rm -f tfplan
    exit 0
  fi

  info "terraform apply ..."
  terraform apply -auto-approve tfplan >> "$LOG_FILE" 2>&1
  rm -f tfplan
  success "Apply complete"

  cd "$SCRIPT_DIR"
}

# ------------------------------------------------------------------------------
# Print Final Outputs
# ------------------------------------------------------------------------------
print_outputs() {
  header "Deployment Complete — Outputs"

  cd "$MAIN_DIR"

  local alb_url ecr_url cluster ecs_service gh_role log_group
  alb_url=$(terraform output -raw alb_dns_name       2>/dev/null || echo "N/A")
  ecr_url=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "N/A")
  cluster=$(terraform output -raw ecs_cluster_name   2>/dev/null || echo "N/A")
  ecs_service=$(terraform output -raw ecs_service_name 2>/dev/null || echo "N/A")
  gh_role=$(terraform output -raw github_actions_role_arn 2>/dev/null || echo "N/A")
  log_group=$(terraform output -raw cloudwatch_log_group 2>/dev/null || echo "N/A")

  echo ""
  echo -e "${BOLD}  App URL         :${RESET} ${GREEN}$alb_url${RESET}"
  echo -e "${BOLD}  ECR Repo        :${RESET} $ecr_url"
  echo -e "${BOLD}  ECS Cluster     :${RESET} $cluster"
  echo -e "${BOLD}  ECS Service     :${RESET} $ecs_service"
  echo -e "${BOLD}  GitHub Role ARN :${RESET} $gh_role"
  echo -e "${BOLD}  CloudWatch Logs :${RESET} $log_group"
  echo ""
  echo -e "${BOLD}  Full log        :${RESET} $LOG_FILE"
  echo ""

  echo -e "${CYAN}${BOLD}  Next steps:${RESET}"
  echo -e "  1. Push a Docker image to ECR:"
  echo -e "     ${CYAN}aws ecr get-login-password --region us-east-1 | \\"
  echo -e "       docker login --username AWS --password-stdin $ecr_url${RESET}"
  echo -e "     ${CYAN}docker tag your-image:latest $ecr_url:latest${RESET}"
  echo -e "     ${CYAN}docker push $ecr_url:latest${RESET}"
  echo ""
  echo -e "  2. Add to GitHub Actions secrets:"
  echo -e "     ${CYAN}AWS_ROLE_ARN = $gh_role${RESET}"
  divider

  cd "$SCRIPT_DIR"
}

# ------------------------------------------------------------------------------
# Destroy — reverse order (service → main → bootstrap)
# ------------------------------------------------------------------------------
run_destroy() {
  header "DESTROY MODE — This will delete all infrastructure"

  warn "This will permanently delete:"
  warn "  • ECS service, cluster, task definitions"
  warn "  • ALB, target groups, listeners"
  warn "  • ECR repository (and all images)"
  warn "  • IAM roles and OIDC provider"
  warn "  • Security groups"
  warn "  • CloudWatch log groups"
  echo ""
  read -r -p "$(echo -e ${RED}${BOLD}'  Type "destroy" to confirm: '${RESET})" confirm

  if [[ "$confirm" != "destroy" ]]; then
    info "Destroy cancelled"
    exit 0
  fi

  # Destroy main infra first
  if [[ -d "$MAIN_DIR" ]]; then
    info "Destroying main infrastructure ..."
    cd "$MAIN_DIR"
    terraform init -input=false >> "$LOG_FILE" 2>&1
    terraform destroy -auto-approve -input=false >> "$LOG_FILE" 2>&1
    success "Main infrastructure destroyed"
    cd "$SCRIPT_DIR"
  fi

  # Restore backend.tf placeholder so bootstrap destroy can run cleanly
  if [[ -f "$BACKEND_FILE.bak" ]]; then
    mv "$BACKEND_FILE.bak" "$BACKEND_FILE"
    info "backend.tf restored to placeholder state"
  fi

  # Destroy bootstrap
  echo ""
  read -r -p "$(echo -e ${RED}${BOLD}'  Also destroy S3 + DynamoDB remote state? [y/N]: '${RESET})" confirm_bootstrap
  if [[ "$confirm_bootstrap" =~ ^[Yy]$ ]]; then
    info "Destroying bootstrap resources ..."
    cd "$BOOTSTRAP_DIR"

    # S3 bucket must be empty before destroy
    local project_name account_id bucket_name
    project_name=$(grep 'project_name' terraform.tfvars | awk -F'"' '{print $2}')
    account_id=$(aws sts get-caller-identity --query Account --output text)
    bucket_name="${project_name}-tf-state-${account_id}"

    info "Emptying S3 bucket: $bucket_name ..."
    aws s3 rm "s3://${bucket_name}" --recursive >> "$LOG_FILE" 2>&1 || true

    terraform destroy -auto-approve -input=false >> "$LOG_FILE" 2>&1
    success "Bootstrap destroyed"
    cd "$SCRIPT_DIR"
  else
    warn "Bootstrap (S3 + DynamoDB) kept — remote state preserved"
  fi

  success "Destroy complete"
}

# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
main() {
  # Fresh log for this run
  echo "==== deploy.sh started at $(date) ====" > "$LOG_FILE"

  echo ""
  echo -e "${CYAN}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║       AWS ECS Fargate Deploy Script      ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"

  local mode="${1:-deploy}"

  case "$mode" in
    destroy)
      preflight_checks
      run_destroy
      ;;
    deploy|"")
      preflight_checks
      run_bootstrap
      patch_backend
      run_main
      print_outputs
      ;;
    *)
      error "Unknown command: $mode"
      echo ""
      echo "  Usage:"
      echo "    ./deploy.sh            # deploy full infrastructure"
      echo "    ./deploy.sh destroy    # destroy all infrastructure"
      exit 1
      ;;
  esac
}

main "$@"
