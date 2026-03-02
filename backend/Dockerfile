# Secure: Modern, supported python base image
FROM python:3.10-slim

WORKDIR /app

# Secure: Create a non-root user and group
RUN addgroup --system appgroup && adduser --system --group appuser

COPY requirements.txt ./

# Secure: Upgrade pip, avoid caching to reduce image size and attack surface
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

# Secure: Change ownership to the non-root user before running
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
