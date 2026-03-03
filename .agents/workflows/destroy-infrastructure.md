---
description: Destroy Terraform Infrastructure on AWS and Azure
---
# Destroy Terraform Infrastructure Workflow

This workflow automates the tear-down of the deployed network architecture and EKS/AKS clusters to prevent unexpected cloud costs.
Ensure you have active AWS (`aws configure`) and Azure (`az login`) credentials before running these steps.

1. Navigate to the AWS Infrastructure directory.
// turbo
2. Destroy AWS components:
```bash
cd infra/aws && terraform destroy -auto-approve
```

3. Return to the root and navigate to the Azure Infrastructure directory.
// turbo
4. Destroy Azure components:
```bash
cd ../../infra/azure && terraform destroy -auto-approve
```
