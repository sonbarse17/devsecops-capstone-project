---
description: Deploy Kubernetes Security Policies and Manifests
---
# Deploy Kubernetes Security Workflow

This workflow automates the deployment of the securely configured Kubernetes manifests, including Kyverno Admission Controls and Zero-Trust Network Policies.

Ensure you have a valid `kubeconfig` pointing to the deployed EKS or AKS cluster.

1. Install Kyverno Engine (if not already present):
```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.4/install.yaml
```

2. Apply Kyverno Admission Control Policies:
// turbo
```bash
kubectl apply -f k8s/policies/
```

3. Setup zero-trust network boundaries:
// turbo
```bash
kubectl apply -f k8s/network-policy.yaml
```

4. Deploy the hardened application containers:
// turbo
```bash
kubectl apply -f k8s/database.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
```

5. Verify that pods are running securely:
```bash
kubectl get pods -A
```
