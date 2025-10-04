# Build stage
FROM python:3.12 AS builder
# install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# copy only dependency files first (better caching) needs to copy readme because of error when running sync 
COPY pyproject.toml README.md ./
COPY tests ./tests

# copy source code
COPY cc_simple_server/ ./cc_simple_server/

# install dependencies without the project itself
RUN uv sync --no-install-project --no-editable

# now install the complete project
RUN uv sync --no-editable

# Final stage  
FROM python:3.12-slim
# set up virtual environment variablest
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Copy virtual environment and tests directories from builder
COPY --from=builder /app/.venv /app/.venv 
COPY --from=builder /app/tests ./tests

# copy source code
COPY cc_simple_server/ ./cc_simple_server/

#Create non-root user
RUN useradd -m user
RUN chown -R user:user /app 
USER user

EXPOSE 8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]

