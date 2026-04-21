FROM regime-base:latest AS builder
RUN pip install --no-cache-dir --prefix=/install yfinance>=0.2.30 \
    regime-market-data@git+https://github.com/govid13427742/regime-market-data.git@main

FROM regime-base:latest
COPY --from=builder /install /usr/local
COPY . /app
EXPOSE 6001
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:6001/health').raise_for_status()"
CMD ["uvicorn", "services.market_data.app:app", "--host", "0.0.0.0", "--port", "6001"]
