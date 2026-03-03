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
FROM gcr.io/distroless/nodejs20-debian11

WORKDIR /app

# Copy specifically what we need from builder
COPY --from=builder /app /app

USER nonroot

EXPOSE 8080

CMD ["server.js"]
