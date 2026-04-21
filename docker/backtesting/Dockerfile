FROM regime-base:latest AS builder
RUN pip install --no-cache-dir --prefix=/install \
    regime-backtesting@git+https://github.com/govid13427742/regime-backtesting.git@main

FROM regime-base:latest
COPY --from=builder /install /usr/local
COPY . /app
EXPOSE 8004
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8004/health').raise_for_status()"
CMD ["uvicorn", "services.backtesting.app:app", "--host", "0.0.0.0", "--port", "8004"]
