FROM ghcr.io/astral-sh/uv:python3.11-trixie-slim

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ssh \
    gcc \
    build-essential \
    libc-dev \
    ffmpeg \
    libsm6 \
    python3-opencv \
    libxext6 \
    tzdata \
    locales \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen