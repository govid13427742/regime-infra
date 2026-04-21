AWS_REGION     ?= us-east-1
CLUSTER_NAME   ?= regime-detection
ECR_REGISTRY   ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_TAG      ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")
SERVICES       := regime-platform regime-market-data regime-feature-engine regime-detection-core regime-backtesting regime-visualization

.PHONY: help build build-base push deploy local infra destroy status logs clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Docker ──────────────────────────────────────────────────────

build-base: ## Build shared base image
	docker build -t regime-base:latest -f docker/base/Dockerfile docker/base/

build: build-base ## Build all service images
	@for svc in $(SERVICES); do \
		dir=$$(echo $$svc | sed 's/regime-//'); \
		echo "Building $$svc..."; \
		docker build -t $$svc:$(IMAGE_TAG) -t $$svc:latest \
			-f docker/$$dir/Dockerfile . ; \
	done

# ── ECR ─────────────────────────────────────────────────────────

ecr-login: ## Authenticate Docker with ECR
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(ECR_REGISTRY)

push: ecr-login ## Push all images to ECR
	@for svc in $(SERVICES); do \
		echo "Pushing $$svc..."; \
		docker tag $$svc:$(IMAGE_TAG) $(ECR_REGISTRY)/$$svc:$(IMAGE_TAG); \
		docker tag $$svc:latest $(ECR_REGISTRY)/$$svc:latest; \
		docker push $(ECR_REGISTRY)/$$svc:$(IMAGE_TAG); \
		docker push $(ECR_REGISTRY)/$$svc:latest; \
	done

# ── Kubernetes ──────────────────────────────────────────────────

deploy: ## Deploy to K8s (production overlay)
	kubectl apply -k k8s/overlays/production/
	kubectl -n regime rollout status deployment --timeout=300s

local: ## Deploy to minikube/kind (local overlay)
	kubectl apply -k k8s/overlays/local/
	kubectl -n regime rollout status deployment --timeout=120s
	@echo "\nGateway: http://localhost:30080"

status: ## Show regime namespace status
	kubectl -n regime get pods,svc,hpa

logs: ## Tail logs from all regime pods
	kubectl -n regime logs -l app.kubernetes.io/part-of=regime-detection --all-containers -f --tail=50

# ── Terraform ───────────────────────────────────────────────────

infra-init: ## Initialize Terraform
	cd terraform && terraform init

infra-plan: ## Preview infrastructure changes
	cd terraform && terraform plan

infra: infra-init ## Provision AWS infrastructure
	cd terraform && terraform apply -auto-approve
	@echo "\nConfigure kubectl:"
	@cd terraform && terraform output -raw configure_kubectl

destroy: ## Tear down AWS infrastructure
	@echo "WARNING: This will destroy all cloud resources!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd terraform && terraform destroy -auto-approve

# ── Full workflows ──────────────────────────────────────────────

up: infra build push deploy ## Full cloud: infra + build + push + deploy

local-up: build local ## Full local: build + deploy to minikube/kind

clean: ## Remove local Docker images
	@for svc in $(SERVICES); do docker rmi $$svc:$(IMAGE_TAG) $$svc:latest 2>/dev/null || true; done
	docker rmi regime-base:latest 2>/dev/null || true
