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
FROM gcr.io/distroless/python3-debian12

# Copy the dependencies from the builder stage
COPY --from=builder /install /usr/local

# Copy application source code
WORKDIR /app
COPY . .

USER nonroot

EXPOSE 5000

CMD ["/usr/bin/python3", "app.py"]
