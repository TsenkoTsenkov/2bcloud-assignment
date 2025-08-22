# DevOps Assignment - Node.js App on Azure

Simple Node.js "Hello World" app deployed to Azure Kubernetes Service with CI/CD and auto-scaling.

## What's included

- **Infrastructure**: AKS cluster + storage account (Terraform)
- **App**: Basic Node.js web server with health endpoint
- **CI/CD**: GitHub Actions pipeline for build and deploy
- **Auto-scaling**: HPA that scales 1-3 pods based on CPU
- **Testing**: Scripts to verify everything works

## Quick Start

### 1. Set up Azure and infrastructure

```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription b99c0710-ded3-407b-b632-9fb5dd7edd13

# Verify you're using the correct subscription
az account show

# Copy and edit terraform variables (if needed)
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars

# Deploy infrastructure
cd infrastructure
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

**Note**: Had to deploy storage account first with local state, then migrate to remote backend.

### 2. Setting up GitHub Actions

Created these secrets in the GitHub repo:
- `AZURE_CREDENTIALS` - Get from: `az ad sp create-for-rbac --name "ghActions" --role Contributor --scopes /subscriptions/b99c0710-ded3-407b-b632-9fb5dd7edd13 --json-auth`

### 3. Deployment steps

Push any change to the `app/` folder and GitHub Actions will:
- Build Docker image
- Push to Azure Container Registry
- Deploy to AKS using Helm

### 4. Connect to Kubernetes cluster

```bash
# Get cluster credentials
az aks get-credentials --resource-group Tsenko-Tsenkov-Candidate --name aks-2bcloud

# Verify connection
kubectl get nodes
kubectl get pods -A
```

### 5. Testing

#### Basic functionality test
```bash
# Get the external IP
kubectl get service nodejs-app -n nodejs-app

# Test main endpoint
curl http://57.153.38.207/

# Test health endpoint
curl http://57.153.38.207/healthz

```

#### Load testing with auto-scaling
```bash
# Check current status
kubectl get pods -n nodejs-app
kubectl get hpa -n nodejs-app

# Run load test (uses Apache Bench)
./load-test-hpa.sh

# Watch scaling in real-time (in separate terminals)
kubectl get hpa -n nodejs-app -w
kubectl get pods -n nodejs-app -w
```
Example of the scaling triggered:
<img width="1342" height="329" alt="Screenshot 2025-08-22 at 22 55 52" src="https://github.com/user-attachments/assets/5b500fa2-8dc1-40de-b2ca-e62c2193606b" />

## Project Structure

```
├── app/                    # Node.js application
├── infrastructure/
│   ├── helm/              # Kubernetes manifests
│   └── main.tf            # Terraform config
├── .github/workflows/     # CI/CD pipeline
└── load-test-hpa.sh       # Load testing script
```

## Issues Encountered

1. Initially pods couldn't pull images. Fixed by ensuring AKS has AcrPull permission on ACR.

2. Permissions issues with GitHub Actions accessing the kubernetes cluster. Adjusted the GitHub actions template.

2. Original app was too lightweight to trigger scaling. Added `/cpu-load` endpoint that does actual CPU work.


## Key Commands Used

```bash
az login
az account set --subscription b99c0710-ded3-407b-b632-9fb5dd7edd13
az ad sp create-for-rbac --name "ghActions" --role Contributor --scopes /subscriptions/b99c0710-ded3-407b-b632-9fb5dd7edd13 --json-auth

terraform init
terraform apply -var-file="terraform.tfvars"
terraform init -migrate-state

az aks get-credentials --resource-group Tsenko-Tsenkov-Candidate --name aks-2bcloud
kubectl get pods -n kube-system | grep metrics
kubectl get hpa -n nodejs-app -w
kubectl get pods -n nodejs-app -w
```

## CI/CD Pipeline
Copied from a template in GitHub Actions

Triggers on changes to:
- `app/**` (application code)
- `infrastructure/helm/**` (Kubernetes manifests)
- `.github/workflows/**` (pipeline itself)

Pipeline steps:
1. Build Docker image
2. Push to ACR
3. Deploy to AKS with Helm

## What the app does

- **GET /**: Returns `{"message": "Hello World!"}`
- **GET /healthz**: Returns health status with timestamp
- **GET /cpu-load**: Does CPU-intensive work (for load testing)

## Auto-scaling Configuration

- **Min pods**: 1
- **Max pods**: 3
- **CPU trigger**: 70%
- **Memory trigger**: 80%
- **Scale up**: every 15s
- **Scale down**: 5min stabilization
