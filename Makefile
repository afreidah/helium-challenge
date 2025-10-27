# -----------------------------------------------------------------------------
# MAKEFILE - TERRAGRUNT/OPENTOFU CI/CD AUTOMATION
# -----------------------------------------------------------------------------
#
# This Makefile provides automation targets for Terraform/Terragrunt
# infrastructure code quality, validation, testing, and deployment workflows.
#
# Target Categories:
#   - Code Quality: Formatting and style checks
#   - Validation: Module and Terragrunt configuration validation
#   - Testing: Terraform native test execution
#   - Workflows: CI/CD pipeline orchestration
#   - Docker: CI toolkit image management
#   - Cleanup: Artifact and cache removal
#
# Common Usage:
#   make fmt          - Format all Terraform and Terragrunt files
#   make validate     - Validate all modules and configurations
#   make test         - Run Terraform tests on all modules
#   make ci           - Run complete CI pipeline (format, validate, test, plan)
#   make plan-all     - Generate Terragrunt plans for all environments
#   make clean        - Remove all build artifacts and caches
#
# Requirements:
#   - terraform or tofu
#   - terragrunt
#   - hclfmt
#   - docker (for containerized workflows)
# -----------------------------------------------------------------------------

# Directories
MODULES_DIR ?= modules
PLAN_DIR    ?= .ci/plan

# Colors
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;36m
NC     := \033[0m

.PHONY: help fmt fmt-check validate-modules validate-terragrunt validate test ci plan-all clean docker-build docker-clean docker-ci cost

# -----------------------------------------------------------------------------
# HELP
# -----------------------------------------------------------------------------

help: ## Show available targets with descriptions
	@printf "\nUsage:\n  make $(YELLOW)<target>$(NC)\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5); next } \
		/^[a-zA-Z0-9_%-]+:.*##/ { printf "  $(BLUE)%-24s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Common targets:$(NC)"
	@printf "  $(BLUE)fmt$(NC), $(BLUE)fmt-check$(NC), $(BLUE)validate$(NC), $(BLUE)test$(NC), $(BLUE)plan-all$(NC), $(BLUE)clean$(NC), $(BLUE)ci$(NC)\n"

# -----------------------------------------------------------------------------
# CODE QUALITY
# -----------------------------------------------------------------------------

##@ Code Quality

fmt: ## Format Terraform (modules) and Terragrunt HCL (live)
	@echo "$(BLUE)Formatting Terraform modules$(NC)"
	@terraform fmt -recursive ./$(MODULES_DIR) || tofu fmt -recursive ./$(MODULES_DIR)
	@echo "$(BLUE)Formatting Terragrunt HCL files$(NC)"
	@find . -type f -name "*.hcl" ! -path "*/.terragrunt-cache/*" -print0 | \
	while IFS= read -r -d '' f; do hclfmt -w "$$f"; done
	@echo "$(GREEN)✓ Formatting complete$(NC)"

fmt-check: ## Check formatting (fail if changes would be needed)
	@echo "$(BLUE)Checking Terraform formatting$(NC)"
	@terraform fmt -check -recursive ./$(MODULES_DIR) || tofu fmt -check -recursive ./$(MODULES_DIR)
	@echo "$(BLUE)Checking Terragrunt HCL formatting$(NC)"
	@changed=0; \
	find . -type f -name "*.hcl" ! -path "*/.terragrunt-cache/*" -print0 | \
	while IFS= read -r -d '' f; do \
		if ! hclfmt -check -require-no-change "$$f" >/dev/null 2>&1; then \
			echo "$(RED)Needs format: $$f$(NC)"; changed=1; \
		fi; \
	done; \
	if [ $$changed -ne 0 ]; then \
		echo "$(RED)✗ Some .hcl files need formatting$(NC)"; exit 1; \
	else \
		echo "$(GREEN)✓ All files formatted correctly$(NC)"; \
	fi

# -----------------------------------------------------------------------------
# VALIDATION
# -----------------------------------------------------------------------------

##@ Validation

validate-modules: ## Validate all Terraform modules (no backend init)
	@echo "$(BLUE)Validating Terraform modules$(NC)"
	@set -e; \
	failed=0; \
	find $(MODULES_DIR)/*/ -maxdepth 0 -type d | \
	xargs -P 4 -I {} bash -c 'echo "$(YELLOW)Validating {}$(NC)" && cd {} && terraform init -backend=false >/dev/null && terraform validate' || failed=$$((failed+1)); \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)✗ Some modules failed validation$(NC)"; exit 1; \
	else \
		echo "$(GREEN)✓ All modules validated$(NC)"; \
	fi

validate-terragrunt: ## Validate Terragrunt configurations (HCL and module references)
	@echo "$(BLUE)Validating Terragrunt live configs$(NC)"
	@failed=0; \
	for f in $(shell find . -type f -name terragrunt.hcl ! -path "*/.terragrunt-cache/*"); do \
		d=$$(dirname "$$f"); \
		echo "$(YELLOW)Validating $$d$(NC)"; \
		hclfmt -check -require-no-change "$$f" >/dev/null 2>&1 || failed=$$(expr $$failed + 1); \
		if grep -q '^[[:space:]]*terraform[[:space:]]*{' "$$f" && grep -q 'source[[:space:]]*=' "$$f"; then \
			( cd "$$d" && terragrunt run -- init -backend=false -input=false >/dev/null 2>&1 && terragrunt run -- validate -no-color ) \
			|| failed=$$(expr $$failed + 1); \
		else \
			echo "  $(YELLOW)(skip) no terraform { source } block$(NC)"; \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)✗ $$failed Terragrunt dir(s) failed validation$(NC)"; exit 1; \
	else \
		echo "$(GREEN)✓ All Terragrunt configs validated$(NC)"; \
	fi

validate: validate-modules validate-terragrunt ## Run both module and Terragrunt validation

# -----------------------------------------------------------------------------
# TESTING
# -----------------------------------------------------------------------------

##@ Testing

test: ## Run terraform test on all modules (parallel)
	@echo "$(BLUE)Running terraform test on all modules$(NC)"
	@find $(MODULES_DIR)/*/ -maxdepth 0 -type d | \
	xargs -P 4 -I {} bash -c 'echo "$(YELLOW)Testing {}$(NC)" && cd {} && terraform init -backend=false >/dev/null && terraform test -parallelism=10'
	@echo "$(GREEN)✓ All modules passed tests$(NC)"

# -----------------------------------------------------------------------------
# WORKFLOWS
# -----------------------------------------------------------------------------

##@ Workflows

plan-all: ## Run Terragrunt plan across all environments and save output
	@echo "$(BLUE)Planning all environments$(NC)"
	@mkdir -p $(PLAN_DIR)
	@set -e; \
	failed=0; \
	for env in production; do \
		echo "$(YELLOW)==> Planning $$env environment$(NC)"; \
		if (cd $$env && TF_IN_AUTOMATION=1 TERRAGRUNT_LOG_LEVEL=error terragrunt run --all -- plan -no-color -compact-warnings) > $(PLAN_DIR)/plan-$$env.txt 2>&1; then \
			echo "$(GREEN)✓ $$env plan successful$(NC)"; \
		else \
			echo "$(RED)✗ $$env plan failed$(NC)"; \
			failed=$$((failed+1)); \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)✗ $$failed environment(s) failed planning$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ All plans saved to $(PLAN_DIR)/$(NC)"; \
	fi

ci: fmt-check validate test plan-all cost
	@echo "$(GREEN)✓ CI checks passed$(NC)"

# -----------------------------------------------------------------------------
# DOCKER
# -----------------------------------------------------------------------------

##@ Docker

DOCKER_IMAGE_NAME ?= helium-ci
DOCKER_TAG        ?= latest

docker-ci: ## Run CI checks inside Docker container (mimics GitHub Actions)
	@echo "$(BLUE)Building Docker image...$(NC)"
	@docker build -t helium-ci:latest .
	@echo "$(BLUE)Running CI checks in container...$(NC)"
	@docker run --rm \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION \
		-v $(PWD):/workspace \
		-w /workspace \
		helium-ci:latest \
		bash -c 'git config --global --add safe.directory /workspace && make ci && make clean'

docker-build: ## Build the CI Docker image (Terragrunt/OpenTofu toolkit)
	@echo "$(BLUE)Building Docker image: $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)$(NC)"
	@docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .
	@echo "$(GREEN)✓ Docker image built successfully: $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)$(NC)"

docker-clean: ## Remove the CI Docker image and dangling layers
	@echo "$(BLUE)Removing Docker image: $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)$(NC)"
	@docker rmi -f $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) 2>/dev/null || true
	@docker image prune -f >/dev/null
	@echo "$(GREEN)✓ Docker cleanup complete$(NC)"

# -----------------------------------------------------------------------------
# INFRACOST
# -----------------------------------------------------------------------------

##@ Cost Estimation

cost: ## Estimate infrastructure costs with Infracost for all environments
	@echo "$(BLUE)Estimating infrastructure costs...$(NC)"
	@if [ -z "$$INFRACOST_API_KEY" ]; then \
		echo "$(RED)INFRACOST_API_KEY not set$(NC)"; \
		exit 1; \
	fi
	@mkdir -p $(PLAN_DIR)
	@for env in production staging; do \
		echo "$(YELLOW)Estimating costs for $$env...$(NC)"; \
		(cd $$env && infracost breakdown --path . --format table 2>&1 | tee ../$(PLAN_DIR)/cost-$$env.txt ) & \
	done; \
	wait
	@echo "$(GREEN)✓ Cost estimates saved to $(PLAN_DIR)/$(NC)"

.PHONY: cost

# -----------------------------------------------------------------------------
# DOCS
# -----------------------------------------------------------------------------

##@ Generate docs for modules

docs: ## Generate README.md documentation for all Terraform modules (parallel)
	@echo "$(BLUE)Generating module documentation$(NC)"
	@find $(MODULES_DIR)/*/ -maxdepth 0 -type d | \
	xargs -P 4 -I {} bash -c 'echo "$(YELLOW)Generating docs for {}$(NC)" && terraform-docs markdown table --output-file README.md --output-mode inject {}'
	@echo "$(GREEN)✓ Documentation generated for all modules$(NC)"

.PHONY: docs

# -----------------------------------------------------------------------------
# CLEANUP
# -----------------------------------------------------------------------------

##@ Cleanup

clean: ## Clean up Terraform/Terragrunt build artifacts and caches
	@echo "$(BLUE)Cleaning Terraform and Terragrunt artifacts$(NC)"
	@find . -type d -name ".terraform" -prune -exec rm -rf {} +
	@find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} +
	@find . -type f -name "*.tfstate" -delete
	@find . -type f -name "*.tfstate.backup" -delete
	@find . -type f -name "*.tfplan" -delete
	@find . -type f -name "plan.json" -delete
	@find . -type f -name ".terragrunt-source-version" -delete
	@find . -type f -name ".checkov.yaml" -delete
	@find . -type f -name ".trivy.yaml" -delete
	@find . -type f -name ".trivyignore" -delete
	@find . -type d -name ".checkov" -prune -exec rm -rf {} +
	@find . -type d -name "$(PLAN_DIR)" -prune -exec rm -rf {} +
	@find . -type f -name "debug.tfvars" -delete
	@echo "$(GREEN)✓ Cleanup complete$(NC)"
