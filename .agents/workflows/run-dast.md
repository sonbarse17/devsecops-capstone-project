---
description: Run Dynamic Application Security Testing (OWASP ZAP)
---
# Run DAST Workflow

This workflow spins up the local application stack and runs the OWASP ZAP baseline scanner against it to identify runtime misconfigurations (e.g., missing security headers).

1. Ensure you are in the project root directory.
// turbo
2. Start the application stack via Docker Compose in detached mode:
```bash
docker compose up -d
```

3. Wait a few seconds for all services to become healthy.
```bash
sleep 10
```

4. Run the OWASP ZAP Docker image against the local frontend.
// turbo
```bash
docker run --network host --rm -v $(pwd):/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://127.0.0.1:8080 -a
```

5. Tear down the application stack to clean up resources:
// turbo
```bash
docker compose down
```
