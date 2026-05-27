FROM python:3.10-slim

# Cài tesseract + tiếng Việt
RUN apt-get update && apt-get install -y \
        tesseract-ocr \
        tesseract-ocr-vie \
        libgl1 \
        libglib2.0-0 \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:${PATH}"

WORKDIR /app

COPY --chown=user:user requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=user:user . .

#CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]