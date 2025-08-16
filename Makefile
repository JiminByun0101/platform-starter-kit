SHELL := /usr/bin/env bash

# Default environment (override: make ENV=staging plan)
ENV ?= dev

# Load .env.<ENV> if it exists
ifneq (,$(wildcard .env.$(ENV)))
include .env.$(ENV)
export
endif

TF_DIR=terraform/gcp/envs/$(ENV)

.PHONY: help init fmt validate plan apply destroy kubeconfig apis whoami tfstate issuer-apply

help: ## Show targets
	@echo "ENV=$(ENV)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS=":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

whoami: ## Show gcloud identity and project
	gcloud config list
	gcloud auth list

apis: ## (One-time) Enable required GCP APIs (idempotent)
	gcloud services enable container.googleapis.com compute.googleapis.com artifactregistry.googleapis.com \
		cloudresourcemanager.googleapis.com iamcredentials.googleapis.com serviceusage.googleapis.com \
		cloudbuild.googleapis.com secretmanager.googleapis.com

fmt: ## Terraform fmt
	cd $(TF_DIR) && terraform fmt -recursive

fmt-all: ## Terraform fmt all envs and modules
	terraform -chdir=terraform/gcp fmt -recursive

validate: ## Terraform validate
	cd $(TF_DIR) && terraform init -backend=false && terraform validate

init: ## Terraform init (uses backend)
	cd $(TF_DIR) && terraform init

reinit: ## Reinitialize backend after changing bucket/prefix
	cd $(TF_DIR) && terraform init -reconfigure

plan: validate ## Terraform plan with tfvars
	cd $(TF_DIR) && terraform plan -var-file=$(ENV).tfvars

apply: ## Terraform apply with tfvars
	cd $(TF_DIR) && terraform apply -auto-approve -var-file=$(ENV).tfvars

destroy: ## Terraform destroy (careful!)
	cd $(TF_DIR) && terraform destroy -auto-approve -var-file=$(ENV).tfvars

kubeconfig: ## Fetch kubeconfig for the current env cluster
	gcloud container clusters get-credentials $(CLUSTER_NAME) --region $(REGION) --project $(PROJECT_ID)

issuer-apply: ## Apply ClusterIssuer (env-rendered)
	@set -a && source .env.$(ENV) && \
	envsubst < argocd/cert-manager-clusterissuer.yaml | kubectl apply -f -

ARGOCD_OVERLAY := .rendered/argocd-values.$(ENV).yaml

render-argocd: ## Render Argo CD overlay from env
	@mkdir -p .rendered
	# Only substitute the vars we expect; leave $oidc.* untouched
	set -a && . .env.$(ENV) && \
	envsubst '$${ARGOCD_HOST} $${GOOGLE_OAUTH_CLIENT_ID} $${GOOGLE_OAUTH_CLIENT_SECRET} $${ARGOCD_ADMIN_EMAIL}' \
		< helm/argocd/values.ingress-sso.tmpl.yaml > $(ARGOCD_OVERLAY)
	@echo "Rendered: $(ARGOCD_OVERLAY)"

argocd-upgrade: render-argocd ## Upgrade Argo CD with ingress/SSO overlay
	helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
	helm repo update
	helm upgrade --install argocd argo/argo-cd \
		--namespace argocd \
		--create-namespace \
		--version 8.2.7 \
		-f helm/argocd/values.yaml \
		-f $(ARGOCD_OVERLAY)