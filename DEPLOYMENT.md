# Book Review App — Production Deployment Guide

A production-grade, three-tier web application deployed on AWS using Infrastructure as Code and CI/CD. This document walks through the full architecture, how to deploy it, and the real problems solved along the way.

---

## Architecture

```
                    Internet
                       |
              [ AWS Load Balancer ]   <-- frontend-service (LoadBalancer)
                       |
        +--------------+--------------+
        |                             |
  [ Frontend Pods ]            [ Backend Pods ]
  Next.js (2 replicas)         Node.js/Express (2 replicas)
        |                             |
        +--------------+--------------+
                       |
              [ Aurora MySQL 8.0 ]     <-- private subnets only
              writer + reader endpoints
```

| Tier | Technology | Runs on |
|------|-----------|---------|
| Presentation | Next.js (multi-stage Docker) | EKS, 2 replicas, LoadBalancer Service |
| Application | Node.js / Express / Sequelize | EKS, 2 replicas, ClusterIP Service |
| Data | Amazon Aurora MySQL 8.0 (`db.t3.medium`) | RDS, private subnets, port 3306 |

### AWS resources (all provisioned via Terraform)

- **VPC** `10.0.0.0/16` — 2 public + 2 private subnets across 2 AZs, IGW, NAT Gateway, route tables
- **EKS** `book-review-production-cluster` — Kubernetes 1.30, 2x `t3.medium` worker nodes
- **RDS** `book-review-aurora-cluster` — Aurora MySQL 8.0, writer + reader endpoints, database `bookreviewdb`
- **ECR** — 2 repositories: `book-review-backend`, `book-review-frontend`

---

## Repository layout

```
book-review-app/
├── modules/
│   ├── vpc/          # VPC, subnets, IGW, NAT, route tables
│   ├── eks/          # EKS cluster, node group, IAM roles, ECR repos
│   └── rds/          # Aurora MySQL cluster, subnet group, security group
├── k8s/
│   ├── namespace.yaml
│   ├── backend/      # deployment, service, configmap, secret
│   └── frontend/     # deployment, service, configmap
├── backend/          # Node.js/Express app + Dockerfile
├── frontend/         # Next.js app + Dockerfile
├── azure-pipelines.yml   # CI/CD: build -> push to ECR -> deploy to EKS
├── deploy.ps1            # Manual deploy alternative (no CI/CD required)
└── DEPLOYMENT.md         # This file
```

---

## Provisioning the infrastructure (Terraform)

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Provisioning order (handled by module dependencies): **VPC -> EKS -> RDS**.

After apply, point kubectl at the cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name book-review-production-cluster
kubectl get nodes   # both nodes should show Ready
```

---

## Deploying the application

### Option A — CI/CD with Azure DevOps (`azure-pipelines.yml`)

Two stages:

1. **Build & Push** — log in to ECR, build both Docker images, push `:BuildId` and `:latest` tags.
2. **Deploy** — configure kubectl, apply namespace, create DB secret, apply ConfigMaps, roll out backend and frontend, print the LoadBalancer URL.

Trigger with **Run pipeline** (a fresh run, not "Re-run failed jobs" — re-runs reuse the old YAML).

> **Note:** New Azure DevOps organizations need a free hosted-parallelism grant before pipelines can run. If runs sit at "not started", request it here: https://aka.ms/azpipelines-parallelism-request

### Option B — Manual deploy (`deploy.ps1`)

No CI/CD dependency. From PowerShell:

```powershell
./deploy.ps1
```

It logs in to ECR, builds and pushes both images, applies all manifests, and prints the public LoadBalancer URL.

---

## Configuration

Backend reads its config from a ConfigMap and Secret (injected via `envFrom`):

**ConfigMap (`backend-config`)** — non-secret:
`DB_HOST`, `DB_NAME`, `DB_PORT`, `NODE_ENV`, `PORT`

**Secret (`backend-secret`)** — created at deploy time, never committed:
`DB_USER`, `DB_PASSWORD`

---

## Troubleshooting (real issues solved on this project)

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `docker push` can't find image | Azure DevOps `Docker@2` didn't expand nested variables in the tag field | Consolidated build + push into a single shell task with explicit ECR URIs |
| Re-run still uses old steps | "Re-run failed jobs" reuses the YAML from the original trigger | Always start a fresh **Run pipeline** |
| `k8s/namespace.yaml does not exist` | `AWSShellScript@1` runs from a temp dir, not the repo root | `cd $(Build.SourcesDirectory)` at the top of each script |
| Path error persisted in `deployment` job | In a `deployment` job, `checkout: self` and `$(Build.SourcesDirectory)` resolve to different paths | Converted the deploy stage to a regular `job` (reliable checkout) |
| Pipeline stuck at "not started" | Free-tier hosted parallelism not granted | Submit the parallelism request form |
| `rollout status ... timed out` | Pods never reach Ready | Check `kubectl get pods -n book-review`; common causes: RDS security group missing inbound 3306 from the node SG, or the `/health` probe not yet returning 200 |

### Quick diagnostics

```bash
kubectl get pods -n book-review
kubectl logs -l app=backend -n book-review --tail=60
kubectl describe pod -l app=backend -n book-review | tail -30
kubectl get svc frontend-service -n book-review
```

---

## Region

All resources are deployed in **us-east-1**.
