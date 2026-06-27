# ──────────────────────────────────────────────────────────────────────────────
# deploy.ps1 — Manual deploy to EKS (no Azure DevOps required)
# Run from repo root in PowerShell. Requires: aws cli, docker, kubectl (all logged in)
#
# Usage:
#   .\deploy.ps1 -DbUser "admin" -DbPassword "YourAuroraPassword"
# ──────────────────────────────────────────────────────────────────────────────
param(
    [Parameter(Mandatory=$true)][string]$DbUser,
    [Parameter(Mandatory=$true)][string]$DbPassword
)

$ErrorActionPreference = "Stop"

$AWS_REGION     = "us-east-1"
$AWS_ACCOUNT_ID = "483519904572"
$ECR_BACKEND    = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/book-review-backend"
$ECR_FRONTEND   = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/book-review-frontend"
$EKS_CLUSTER    = "book-review-production-cluster"
$NS             = "book-review"

Write-Host "==> [1/7] Configuring kubectl for EKS..." -ForegroundColor Cyan
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER

Write-Host "==> [2/7] Logging into ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region $AWS_REGION | `
    docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

Write-Host "==> [3/7] Building & pushing BACKEND image..." -ForegroundColor Cyan
docker build -t "${ECR_BACKEND}:latest" ./backend
docker push "${ECR_BACKEND}:latest"

Write-Host "==> [4/7] Building & pushing FRONTEND image..." -ForegroundColor Cyan
docker build -t "${ECR_FRONTEND}:latest" ./frontend
docker push "${ECR_FRONTEND}:latest"

Write-Host "==> [5/7] Applying namespace, configmaps & secret..." -ForegroundColor Cyan
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend/configmap.yaml
kubectl apply -f k8s/frontend/configmap.yaml

# DB secret built from params (never committed to git)
kubectl create secret generic backend-secret `
    --namespace=$NS `
    --from-literal=DB_USER="$DbUser" `
    --from-literal=DB_PASSWORD="$DbPassword" `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host "==> [6/7] Deploying backend & frontend..." -ForegroundColor Cyan
kubectl apply -f k8s/backend/deployment.yaml
kubectl apply -f k8s/backend/service.yaml
kubectl apply -f k8s/frontend/deployment.yaml
kubectl apply -f k8s/frontend/service.yaml

kubectl rollout status deployment/backend  -n $NS --timeout=180s
kubectl rollout status deployment/frontend -n $NS --timeout=180s

Write-Host "==> [7/7] Fetching public LoadBalancer URL..." -ForegroundColor Cyan
Write-Host "Waiting ~45s for AWS ELB to provision..." -ForegroundColor Yellow
Start-Sleep -Seconds 45
$LB = kubectl get svc frontend-service -n $NS -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " DEPLOY COMPLETE" -ForegroundColor Green
Write-Host " App URL:  http://$LB" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Run 'kubectl get all -n book-review' to see everything."
