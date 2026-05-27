#!/usr/bin/env bash

# Cài Tesseract
#apt-get update
#apt-get install -y tesseract-ocr tesseract-ocr-vie

# Chạy server
uvicorn main:app --host 0.0.0.0 --port $PORT