FROM regime-base:latest AS builder
RUN pip install --no-cache-dir --prefix=/install hmmlearn>=0.3 \
    regime-detection-core@git+https://github.com/RegimeDetectionApp/regime-detection-core.git@main \
    regime-feature-engine@git+https://github.com/RegimeDetectionApp/regime-feature-engine.git@main

FROM regime-base:latest
COPY --from=builder /install /usr/local
COPY . /app
EXPOSE 6003
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:6003/health').raise_for_status()"
CMD ["uvicorn", "services.detection_core.app:app", "--host", "0.0.0.0", "--port", "6003"]
