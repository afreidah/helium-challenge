# =============================================================================
# Multi-stage Dockerfile for Terragrunt/OpenTofu CI toolkit
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder - Download/build all tools (Go 1.25.1 for hclfmt)
# -----------------------------------------------------------------------------
FROM golang:1.25.1-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Pin versions here (your versions)
ENV TERRAFORM_VERSION=1.13.4 \
    OPENTOFU_VERSION=1.10.6 \
    TERRAGRUNT_VERSION=0.91.5 \
    TFLINT_VERSION=0.59.1 \
    TRIVY_VERSION=0.67.2 \
    TERRAFORM_DOCS_VERSION=0.20.0 \
    GITLEAKS_VERSION=8.21.2 \
    INFRACOST_VERSION=0.10.42

WORKDIR /tmp

# Base build deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip tar git jq make bash \
  && rm -rf /var/lib/apt/lists/*

# Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
  && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
  && chmod +x /usr/local/bin/terraform \
  && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# OpenTofu
RUN wget -q https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip \
  && unzip tofu_${OPENTOFU_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
  && chmod +x /usr/local/bin/tofu \
  && rm -f tofu_${OPENTOFU_VERSION}_linux_amd64.zip

# Terragrunt
RUN wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
  -O /usr/local/bin/terragrunt \
  && chmod +x /usr/local/bin/terragrunt

# tflint
RUN wget -q https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
  && unzip tflint_linux_amd64.zip -d /usr/local/bin/ \
  && chmod +x /usr/local/bin/tflint \
  && rm -f tflint_linux_amd64.zip

# trivy (binary tarball)
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz \
  && tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz -C /usr/local/bin/ trivy \
  && chmod +x /usr/local/bin/trivy \
  && rm -f trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz

# terraform-docs
RUN wget -q https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz \
  && tar -xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz -C /usr/local/bin/ terraform-docs \
  && chmod +x /usr/local/bin/terraform-docs \
  && rm -f terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz

# gitleaks
RUN wget -q https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz \
  && tar -xzf gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz -C /usr/local/bin/ gitleaks \
  && chmod +x /usr/local/bin/gitleaks \
  && rm -f gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz

# infracost
RUN wget -q https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz \
  && tar -xzf infracost-linux-amd64.tar.gz -C /usr/local/bin/ infracost-linux-amd64 \
  && mv /usr/local/bin/infracost-linux-amd64 /usr/local/bin/infracost \
  && chmod +x /usr/local/bin/infracost \
  && rm -f infracost-linux-amd64.tar.gz

# hclfmt (build from source) – Go 1.25.1 satisfies the toolchain requirement
RUN go install github.com/hashicorp/hcl/v2/cmd/hclfmt@latest \
  && cp /go/bin/hclfmt /usr/local/bin/hclfmt

# -----------------------------------------------------------------------------
# Stage 2: Final image - minimal runtime + Python tools
# -----------------------------------------------------------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="8am-project"
LABEL description="Terragrunt/OpenTofu tooling image: opentofu, terragrunt, terraform, trivy, checkov, tflint, terraform-docs, gitleaks, hclfmt, infracost"
LABEL version="1.0"

# Runtime deps (keep small)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip \
    git ca-certificates curl jq make graphviz bash \
    unzip wget tar \
    awscli \
  && rm -rf /var/lib/apt/lists/*

# Python tools
RUN pip3 install --no-cache-dir --upgrade \
    checkov \
    pre-commit

# Copy binaries from builder
COPY --from=builder /usr/local/bin/terraform /usr/local/bin/
COPY --from=builder /usr/local/bin/tofu /usr/local/bin/
COPY --from=builder /usr/local/bin/terragrunt /usr/local/bin/
COPY --from=builder /usr/local/bin/tflint /usr/local/bin/
COPY --from=builder /usr/local/bin/trivy /usr/local/bin/
COPY --from=builder /usr/local/bin/terraform-docs /usr/local/bin/
COPY --from=builder /usr/local/bin/gitleaks /usr/local/bin/
COPY --from=builder /usr/local/bin/hclfmt /usr/local/bin/
COPY --from=builder /usr/local/bin/infracost /usr/local/bin/

# Workspace
WORKDIR /workspace

# Quick sanity check (non-fatal)
RUN echo "========================================" && \
    echo "Tool Versions Installed:" && \
    echo "========================================" && \
    echo "Terraform:       $(terraform version -json | jq -r .terraform_version || true)" && \
    echo "OpenTofu:        $(tofu version -json | jq -r .terraform_version || true)" && \
    echo "Terragrunt:      $(terragrunt --version 2>/dev/null | head -n1 || true)" && \
    echo "tflint:          $(tflint --version 2>/dev/null | head -n1 || true)" && \
    echo "trivy:           $(trivy --version 2>/dev/null | head -n1 || true)" && \
    echo "terraform-docs:  $(terraform-docs --version 2>/dev/null | awk '{print $3}' || true)" && \
    echo "gitleaks:        $(gitleaks version 2>/dev/null || true)" && \
    echo "hclfmt:          $(hclfmt -version 2>/dev/null || true)" && \
    echo "Checkov:         $(checkov --version 2>/dev/null || true)" && \
    echo "Pre-commit:      $(pre-commit --version 2>/dev/null | awk '{print $2}' || true)" && \
    echo "AWS CLI:         $(aws --version 2>&1 || true)" && \
    echo "Infracost:       $(infracost --version 2>/dev/null || true)" && \
    echo "========================================"

SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash"]
