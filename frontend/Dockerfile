# Secure: Using an updated, smaller alpine base image
FROM node:20-alpine

# Secure: Set app directory
WORKDIR /usr/src/app

# Secure: Copy and install before copying the rest
COPY package*.json ./
RUN npm ci

COPY . .

# Secure: Assign permissions and use a non-root user (node is created by alpine base)
RUN chown -R node:node /usr/src/app
USER node

# Secure: Exposing an unprivileged port (8080)
EXPOSE 8080

CMD ["npm", "start"]
