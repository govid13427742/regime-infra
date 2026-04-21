FROM regime-base:latest
COPY . /app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health').raise_for_status()"
CMD ["uvicorn", "gateway.app:app", "--host", "0.0.0.0", "--port", "8000"]
