# Terraform commands.
#
# Usage:
#   make plan                       # plan against $ENV (default: dev)
#   make apply                      # apply the most recent plan
#   make fmt                        # terraform fmt -recursive on the whole tree
#   make validate                   # terraform validate against $ENV
#   make tflint                     # tflint the module + envs
#   make shellcheck                 # lint the shell scripts
#
# plan/apply/destroy assume AWS credentials are already in the environment
# (e.g., from `aws sso login`). apply also needs a recent AWS CLI v2: the
# inference targets are created via `aws bedrock-agentcore-control`, outside
# Terraform's providers.

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

ENV ?= dev
ENV_DIR := environments/$(ENV)
TF     ?= terraform
TFLINT ?= tflint

SCRIPTS := modules/agentcore-gateway/scripts/inference-target.sh scripts/test-inference.sh

.PHONY: help init plan apply destroy fmt fmt-check validate tflint shellcheck

help:                            ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init:                            ## terraform init for the current ENV (S3 backend, see backend.tf).
	$(TF) -chdir=$(ENV_DIR) init

plan:                            ## terraform plan for the current ENV.
	$(TF) -chdir=$(ENV_DIR) plan -out=tfplan

apply:                           ## terraform apply the most recent plan.
	$(TF) -chdir=$(ENV_DIR) apply tfplan

destroy:                         ## terraform destroy the current ENV (DANGEROUS).
	$(TF) -chdir=$(ENV_DIR) destroy

fmt:                             ## terraform fmt across the whole tree.
	$(TF) fmt -recursive

fmt-check:                       ## terraform fmt -check (no writes).
	$(TF) fmt -check -recursive

validate:                        ## terraform validate the current ENV.
	$(TF) -chdir=$(ENV_DIR) validate

tflint:                          ## tflint modules and envs.
	$(TFLINT) --recursive

shellcheck:                      ## Lint and format-check the shell scripts.
	shellcheck $(SCRIPTS)
	shfmt -i 2 -d $(SCRIPTS)
