# Insecure: Outdated python image
FROM python:3.6

WORKDIR /app

# Insecure: Running as root by default
COPY requirements.txt ./

# Insecure: Pip install without hash checking on outdated pip
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
