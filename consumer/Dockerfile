FROM python:3.9-slim

# Gerekli paketler
RUN pip install pika

# Script'i kopyala
COPY consumer.py /app/consumer.py

# Script'i çalıştır
CMD ["python", "/app/consumer.py"]

