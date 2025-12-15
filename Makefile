# ============================================================================
# Makefile - Terraform Stack Orchestration
# ============================================================================
# Usage:
#   make init-all          - Initialize all stacks
#   make plan-foundation   - Plan foundation stack
#   make apply-foundation  - Apply foundation stack
#   make plan-workspaces   - Plan workspaces stack
#   make apply-workspaces  - Apply workspaces stack
#   make deploy-all        - Deploy foundation then workspaces
#   make destroy-all       - Destroy workspaces then foundation (reverse order)
# ============================================================================

.PHONY: help init-all plan-foundation apply-foundation plan-workspaces apply-workspaces deploy-all destroy-all

# Default target
help:
	@echo "Terraform Multi-Workspace Stack Orchestration"
	@echo ""
	@echo "Initialization:"
	@echo "  make init-all              - Initialize all stacks"
	@echo "  make init-foundation       - Initialize foundation stack"
	@echo "  make init-workspaces       - Initialize workspaces stack"
	@echo ""
	@echo "Foundation Stack (Azure + Account resources):"
	@echo "  make plan-foundation       - Plan foundation changes"
	@echo "  make apply-foundation      - Apply foundation changes"
	@echo "  make destroy-foundation    - Destroy foundation resources"
	@echo ""
	@echo "Workspaces Stack (Per-workspace resources):"
	@echo "  make plan-workspaces       - Plan workspaces changes"
	@echo "  make apply-workspaces      - Apply workspaces changes"
	@echo "  make destroy-workspaces    - Destroy workspaces resources"
	@echo ""
	@echo "Full Deployment:"
	@echo "  make deploy-all            - Deploy foundation, then workspaces"
	@echo "  make destroy-all           - Destroy workspaces, then foundation"
	@echo ""
	@echo "Utility:"
	@echo "  make validate-all          - Validate all stacks"
	@echo "  make fmt                   - Format all Terraform files"
	@echo "  make output-foundation     - Show foundation outputs"
	@echo ""

# ============================================================================
# Variables
# ============================================================================
FOUNDATION_DIR := stacks/foundation
WORKSPACES_DIR := stacks/workspaces
TF_VARS_FILE := terraform.tfvars

# ============================================================================
# Initialization
# ============================================================================
init-foundation:
	@echo ">>> Initializing foundation stack..."
	cd $(FOUNDATION_DIR) && terraform init

init-workspaces:
	@echo ">>> Initializing workspaces stack..."
	cd $(WORKSPACES_DIR) && terraform init

init-all: init-foundation init-workspaces
	@echo ">>> All stacks initialized!"

# ============================================================================
# Foundation Stack Operations
# ============================================================================
plan-foundation:
	@echo ">>> Planning foundation stack..."
	cd $(FOUNDATION_DIR) && terraform plan -var-file=../../$(TF_VARS_FILE)

apply-foundation:
	@echo ">>> Applying foundation stack..."
	cd $(FOUNDATION_DIR) && terraform apply -var-file=../../$(TF_VARS_FILE)

apply-foundation-auto:
	@echo ">>> Applying foundation stack (auto-approve)..."
	cd $(FOUNDATION_DIR) && terraform apply -auto-approve -var-file=../../$(TF_VARS_FILE)

destroy-foundation:
	@echo ">>> Destroying foundation stack..."
	cd $(FOUNDATION_DIR) && terraform destroy -var-file=../../$(TF_VARS_FILE)

output-foundation:
	@echo ">>> Foundation stack outputs..."
	cd $(FOUNDATION_DIR) && terraform output

# ============================================================================
# Workspaces Stack Operations
# ============================================================================
plan-workspaces:
	@echo ">>> Planning workspaces stack..."
	cd $(WORKSPACES_DIR) && terraform plan -var-file=../../$(TF_VARS_FILE)

apply-workspaces:
	@echo ">>> Applying workspaces stack..."
	cd $(WORKSPACES_DIR) && terraform apply -var-file=../../$(TF_VARS_FILE)

apply-workspaces-auto:
	@echo ">>> Applying workspaces stack (auto-approve)..."
	cd $(WORKSPACES_DIR) && terraform apply -auto-approve -var-file=../../$(TF_VARS_FILE)

destroy-workspaces:
	@echo ">>> Destroying workspaces stack..."
	cd $(WORKSPACES_DIR) && terraform destroy -var-file=../../$(TF_VARS_FILE)

# ============================================================================
# Full Deployment
# ============================================================================
deploy-all: init-all apply-foundation-auto
	@echo ">>> Extracting workspace URLs from foundation outputs..."
	@echo ">>> Please update tfvars with workspace URLs, then run: make apply-workspaces"
	@echo ""
	@echo "Workspace URLs:"
	@cd $(FOUNDATION_DIR) && terraform output -json workspace_urls
	@echo ""
	@echo "Next steps:"
	@echo "1. Copy workspace URLs to terraform.tfvars"
	@echo "2. Run: make apply-workspaces"

deploy-workspaces-after-foundation: apply-workspaces-auto
	@echo ">>> Full deployment complete!"

destroy-all: destroy-workspaces
	@echo ">>> Workspaces destroyed. Now destroying foundation..."
	$(MAKE) destroy-foundation
	@echo ">>> Full teardown complete!"

# ============================================================================
# Validation & Formatting
# ============================================================================
validate-foundation:
	cd $(FOUNDATION_DIR) && terraform validate

validate-workspaces:
	cd $(WORKSPACES_DIR) && terraform validate

validate-all: validate-foundation validate-workspaces
	@echo ">>> All stacks validated!"

fmt:
	terraform fmt -recursive
	@echo ">>> All Terraform files formatted!"

# ============================================================================
# Utility Commands
# ============================================================================
# Get workspace URLs from foundation and format for tfvars
get-workspace-urls:
	@echo "# Add these to your terraform.tfvars for workspaces stack:"
	@cd $(FOUNDATION_DIR) && terraform output -json workspace_urls | jq -r 'to_entries | .[] | "workspace_\(.key)_host = \"\(.value)\""'

