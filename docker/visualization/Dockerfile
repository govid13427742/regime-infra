FROM regime-base:latest AS builder
RUN pip install --no-cache-dir --prefix=/install matplotlib>=3.7 \
    regime-visualization@git+https://github.com/govid13427742/regime-visualization.git@main

FROM regime-base:latest
COPY --from=builder /install /usr/local
ENV MPLBACKEND=Agg
COPY . /app
EXPOSE 8005
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8005/health').raise_for_status()"
CMD ["uvicorn", "services.visualization.app:app", "--host", "0.0.0.0", "--port", "8005"]
