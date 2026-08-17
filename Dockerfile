ARG PYTHON_VERSION=3.14

FROM ghcr.io/astral-sh/uv:python$PYTHON_VERSION-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# نصب پیش‌نیازها به همراه curl و unzip برای نصب bun
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libc6-dev \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# اصلاح آدرس نصب ابزار Bun در محیط بیلد برای حل ارور فرانت‌اند
RUN curl -fsSL https://bun.sh | bash
ENV PATH="/root/.bun/bin:$PATH"

WORKDIR /build

COPY uv.lock pyproject.toml /build/
RUN uv sync --frozen --no-install-project --no-dev

COPY . /build
RUN uv sync --frozen --no-dev

# اجرای بیلد فرانت‌اند در زمان ساخت داکرفایل تا در زمان اجرا به ارور نخورد
RUN cd /build/dashboard && bun install && bun run build

FROM python:$PYTHON_VERSION-slim-bookworm

COPY --from=builder /build /code
WORKDIR /code

ENV PATH="/code/.venv/bin:$PATH"
# اضافه کردن مسیر بن به محیط نهایی
COPY --from=builder /root/.bun /root/.bun
ENV PATH="/root/.bun/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY cli_wrapper.sh /usr/bin/pasarguard-cli
RUN chmod +x /usr/bin/pasarguard-cli

COPY tui_wrapper.sh /usr/bin/pasarguard-tui
RUN chmod +x /usr/bin/pasarguard-tui

COPY healthcheck.sh /code/healthcheck.sh
RUN chmod +x /code/healthcheck.sh

RUN chmod +x /code/start.sh

ENTRYPOINT ["/code/start.sh"]
