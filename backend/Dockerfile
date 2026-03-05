FROM python:3.10-slim AS builder

WORKDIR /app
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM gcr.io/distroless/python3-debian12

COPY --from=builder /install /usr/local

WORKDIR /app
COPY . .

USER nonroot

EXPOSE 5000

CMD ["/usr/bin/python3", "app.py"]
