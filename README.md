# regime-infra

Infrastructure-as-Code for deploying the Regime Detection microservices to Kubernetes (local or AWS EKS).

## Architecture

```
              ┌──────────────────────────────┐
              │        AWS EKS Cluster        │
              │   (or minikube/kind local)    │
              ├──────────────────────────────┤
              │  Ingress (nginx)              │
              │       │                       │
              │  Gateway :6000 (LoadBalancer)  │
              │       │                       │
              │  ┌────┴────┬────┬────┬────┐  │
              │  │    │    │    │    │     │  │
              │ :6001 :6002 :6003 :6004 :6005 │
              │ Data  Feat  HMM  Back  Viz    │
              └──────────────────────────────┘
```

## Quick Start

### Local (minikube/kind)
```bash
make build
bash scripts/local-setup.sh
# Open http://localhost:30080
```

### AWS EKS
```bash
# 1. Provision infrastructure
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
make infra

# 2. Build and push images
make build push

# 3. Deploy to EKS
make deploy

# 4. Check status
make status
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make build` | Build all Docker images |
| `make push` | Push images to ECR |
| `make deploy` | Deploy to K8s (production) |
| `make local` | Deploy to minikube/kind |
| `make infra` | Terraform apply (VPC + EKS + ECR) |
| `make destroy` | Terraform destroy |
| `make up` | Full cloud: infra + build + push + deploy |
| `make local-up` | Full local: build + deploy |
| `make status` | Show pod/service status |
| `make logs` | Tail all service logs |

## Terraform Modules

| Module | Resources |
|--------|-----------|
| `vpc` | VPC, public/private subnets, NAT gateway, route tables |
| `eks` | EKS cluster, IAM roles, managed node group |
| `ecr` | ECR repositories (6) with lifecycle policies |

## Kubernetes Resources

- **Namespace**: `regime`
- **ConfigMap**: Service discovery URLs
- **Deployments**: 6 services with health probes and resource limits
- **Services**: ClusterIP (microservices) + LoadBalancer (gateway)
- **HPA**: Detection Core auto-scales 2-8 pods at 70% CPU
- **Ingress**: Nginx with 300s timeout for long-running HMM operations
- **Overlays**: `local` (NodePort, low resources) and `production` (EKS)
