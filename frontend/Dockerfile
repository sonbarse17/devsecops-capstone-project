# ==========================================
# Builder Stage: Compile/Install Node Modules
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./

# Install dependencies exclusively
RUN npm ci

COPY . .

# ==========================================
# Runtime Stage: Google Distroless
# ==========================================
# Secure: No OS shell or utilities, reducing runtime attack surface
FROM gcr.io/distroless/nodejs20-debian11

WORKDIR /app

# Copy specifically what we need from builder
COPY --from=builder /app /app

# Secure: Run as the built-in nonroot user (uid 65532)
USER nonroot

EXPOSE 8080

CMD ["server.js"]
