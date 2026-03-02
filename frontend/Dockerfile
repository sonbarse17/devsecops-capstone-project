# Insecure: Using an outdated base image
FROM node:14

WORKDIR /app

# Insecure: Running as root user (default)
COPY package*.json ./
RUN npm install

COPY . .

# Insecure: Exposing privileged port 80
EXPOSE 80

CMD ["npm", "start"]
