FROM python:3.11-slim

RUN apt-get update && apt-get install -y gcc libffi-dev libssl-dev && \
    pip install --upgrade pip && \
    pip install kubernetes requests && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
COPY scale_script.py /app/scale_script.py
WORKDIR /app

CMD ["python3","-u", "scale_script.py"]

