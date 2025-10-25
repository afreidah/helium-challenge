SHELL := /usr/bin/env bash

# Directories
MODULES_DIR ?= modules

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;36m
NC := \033[0m

##@ General

.PHONY: help fmt fmt-check validate-modules validate-terragrunt validate test ci checkov plan-all clean

##@ General

help: ## Show available targets for formatting, validation, tests, planning, and cleanup
	@printf "\nUsage:\n  make $(YELLOW)<target>$(NC)\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5); next } \
		/^[a-zA-Z0-9_%-]+:.*##/ { printf "  $(BLUE)%-24s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Common targets:$(NC)"
	@printf "  $(BLUE)fmt$(NC), $(BLUE)fmt-check$(NC), $(BLUE)validate$(NC), $(BLUE)test$(NC), $(BLUE)plan-all$(NC), $(BLUE)checkov$(NC), $(BLUE)clean$(NC), $(BLUE)ci$(NC)\n"


##@ Code Quality

fmt: ## Format Terraform (modules) and Terragrunt HCL (live)
	@echo "Formatting Terraform (modules)"
	@terraform fmt -recursive ./modules || tofu fmt -recursive ./modules
	@echo "Formatting Terragrunt HCL (live)"
	@find . -type f -name "*.hcl" ! -path "*/.terragrunt-cache/*" -print0 | \
	while IFS= read -r -d '' f; do hclfmt -w "$$f"; done

fmt-check: ## Check formatting (fail if changes would be needed)
	@echo "Checking Terraform formatting (modules)"
	@terraform fmt -check -recursive ./modules || tofu fmt -check -recursive ./modules
	@echo "Checking Terragrunt HCL formatting (live)"
	@changed=0; \
	find . -type f -name "*.hcl" ! -path "*/.terragrunt-cache/*" -print0 | \
	while IFS= read -r -d '' f; do \
		if ! hclfmt -check -require-no-change "$$f" >/dev/null 2>&1; then \
			echo "Needs format: $$f"; changed=1; \
		fi; \
	done; \
	if [ $$changed -ne 0 ]; then \
		echo "✗ Some .hcl files need formatting"; exit 1; \
	else \
		echo "✓ Terragrunt HCL formatting ok"; \
	fi

##@ Validation

validate-modules: ## terraform validate for each module (no backend init)
	@echo "$(BLUE)Validating Terraform modules$(NC)"
	@set -e; \
	failed=0; \
	for dir in $(MODULES_DIR)/*/; do \
		echo "$(YELLOW)Validating $$dir$(NC)"; \
		( cd "$$dir" && terraform init -backend=false >/dev/null && terraform validate ) || failed=$$((failed+1)); \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)✗ $$failed module(s) failed validation$(NC)"; exit 1; \
	else \
		echo "$(GREEN)✓ All modules validated$(NC)"; \
	fi

validate-terragrunt: ## Validate Terragrunt stacks (HCL only; run tofu validate only where a module source exists)
	@echo "Validating Terragrunt live configs"
	@failed=0; \
	for f in $(shell find . -type f -name terragrunt.hcl ! -path "*/.terragrunt-cache/*"); do \
		d=$$(dirname "$$f"); \
		echo "Validating $$d"; \
		hclfmt -check "$$f" || failed=$$(expr $$failed + 1); \
		if grep -q '^[[:space:]]*terraform[[:space:]]*{' "$$f" && grep -q 'source[[:space:]]*=' "$$f"; then \
			( cd "$$d" && terragrunt run -- init -backend=false -input=false >/dev/null 2>&1 && terragrunt run -- validate -no-color ) \
			|| failed=$$(expr $$failed + 1); \
		else \
			echo "  (skip) no terraform { source } block"; \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo "✗ One or more Terragrunt dir(s) failed validation"; exit 1; \
	else \
		echo "✓ All Terragrunt dirs validated"; \
	fi

validate: validate-modules validate-terragrunt ## Run both module and Terragrunt validation

##@ Security Scanning

checkov: ## Run Checkov against the whole repo
	@echo "Running Checkov (checkov -d .)"
	@command -v checkov >/dev/null 2>&1 || { echo "Error: checkov not installed"; exit 1; }
	@checkov -d . || { echo "✗ Checkov failed"; exit 1; }
	@echo "✓ Checkov passed"

##@ Testing

test: ## Run terraform test on all modules
	@echo "$(BLUE)Running terraform test on all modules...$(NC)"
	@set -e; \
	failed=0; \
	for dir in $(MODULES_DIR)/*/; do \
		echo "$(YELLOW)Testing $$dir$(NC)"; \
		( cd "$$dir" && terraform init -backend=false >/dev/null && terraform test -parallelism=10 ) || failed=$$((failed+1)); \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo "$(RED)✗ $$failed module(s) failed tests$(NC)"; exit 1; \
	else \
		echo "$(GREEN)✓ All modules passed tests$(NC)"; \
	fi

##@ Workflows

## Run Terragrunt plan across all environments
plan-all:
	@set -e; \
	for env in staging production; do \
	  echo "==> Running plan in $$env"; \
	  (cd $$env && terragrunt --non-interactive run --all plan); \
	done

ci: fmt-check validate test ## Run formatting check, validation, and module tests
	@echo "$(GREEN)✓ CI checks passed$(NC)"

## Clean up Terraform/Terragrunt build artifacts and caches
clean:
	@echo "Cleaning Terraform and Terragrunt artifacts..."
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
	@find . -type f -name "debug.tfvars" -delete
	@echo "Cleanup complete."

