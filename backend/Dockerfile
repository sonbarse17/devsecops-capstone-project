# ==========================================
# Builder Stage: Install dependencies
# ==========================================
FROM python:3.10-slim AS builder

WORKDIR /app
COPY requirements.txt .

# Install dependencies into a specific directory for easy copying
# Using --prefix allows us to neatly copy the installed packages
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==========================================
# Runtime Stage: Google Distroless
# ==========================================
# Secure: Distroless image contains no shell, curl, or package managers
FROM gcr.io/distroless/python3-debian12

# Copy the dependencies from the builder stage
COPY --from=builder /install /usr/local

# Copy application source code
WORKDIR /app
COPY . .

# Secure: Unprivileged user (Distroless includes a nonroot user 65532 by default)
USER nonroot

EXPOSE 5000

# Secure: Use absolute path to the Python runtime built into Distroless
CMD ["/usr/bin/python3", "app.py"]
