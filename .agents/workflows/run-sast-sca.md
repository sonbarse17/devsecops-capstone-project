---
description: Run Static Application Security Testing (SAST) and Software Composition Analysis (SCA)
---
# Run SAST & SCA Workflow

This workflow executes multiple security scanners locally against the codebase to mimic the CI pipeline.

1. Ensure you are in the project root directory.
// turbo
2. Run `pre-commit` to execute Bandit (Python SAST), Gitleaks (Secrets), and formatters:
```bash
pre-commit run --all-files
```

3. Navigate to the `frontend` directory.
// turbo
4. Run npm audit for SCA:
```bash
npm ci && npm audit
```

5. Navigate to the `backend` directory.
// turbo
6. Run pip-audit for SCA:
```bash
pip install pip-audit && pip-audit -r requirements.txt
```

7. Return to the project root directory.
// turbo
8. Run Trivy configured for IaC scanning (if Trivy is installed locally):
```bash
trivy config ./infra/ ./k8s/ --severity HIGH,CRITICAL --ignore-unfixed true
```
