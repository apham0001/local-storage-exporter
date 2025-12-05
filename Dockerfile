FROM ghcr.io/astral-sh/uv:0.9.15-python3.14-trixie-slim@sha256:fcc24916ddd11826f45a1f5d50db5222eb1e358af2d9b28936298d8d37854c0e AS builder

COPY . /app
WORKDIR /app

# Install Python in builder stage and copy to final image to maintain consistent Debian base
ENV UV_PYTHON_INSTALL_DIR=/python
RUN uv python install 3.14
RUN uv sync --locked --no-dev # It will create a virtual environment in /app/.venv

FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016

COPY --from=builder /python /python
COPY --from=builder /app /app
WORKDIR /app

ENV PATH="/app/.venv/bin:$PATH"

CMD ["python", "-m", "local_storage_exporter"]