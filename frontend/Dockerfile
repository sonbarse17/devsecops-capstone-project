FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./

RUN npm ci

COPY . .

FROM gcr.io/distroless/nodejs20-debian11

WORKDIR /app

COPY --from=builder /app /app

USER nonroot

EXPOSE 8080

CMD ["server.js"]
