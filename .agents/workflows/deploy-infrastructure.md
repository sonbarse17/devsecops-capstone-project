---
description: Deploy Terraform Infrastructure to AWS and Azure
---
# Deploy Terraform Infrastructure Workflow

This workflow automates the deployment of the hardened network architecture and EKS/AKS clusters.
Ensure you have active AWS (`aws configure`) and Azure (`az login`) credentials before running these steps.

1. Navigate to the AWS Infrastructure directory.
// turbo
2. Initialize and deploy AWS components:
```bash
cd infra/aws && terraform init && terraform apply -auto-approve
```

3. Return to the root and navigate to the Azure Infrastructure directory.
// turbo
4. Initialize and deploy Azure components:
```bash
cd ../../infra/azure && terraform init && terraform apply -auto-approve
```

5. Record any outputted generated IDs or VPC metadata for later use in Kubernetes context setup.
