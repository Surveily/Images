# Copyright (c) Surveily sp. z o.o. All rights reserved.
ARG tag=r35.1.0
ARG jetpack=5.0.2
ARG triton=2.24.0
FROM nvcr.io/nvidia/l4t-tensorrt:r8.4.1-runtime

ARG tag
ARG triton
ARG jetpack

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

# Update
RUN apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Dependencies
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    autoconf \
    automake \
    build-essential \
    cmake \
    git \
    libb64-dev \
    libre2-dev \
    libssl-dev \
    libtool \
    libboost-dev \
    libcurl4-openssl-dev \
    libopenblas-dev \
    rapidjson-dev \
    patchelf \
    zlib1g-dev && \
    # Clean up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Add Triton Server
WORKDIR /opt/tritonserver

RUN wget https://github.com/triton-inference-server/server/releases/download/v${triton}/tritonserver${triton}-jetpack${jetpack}.tgz -O triton.tgz && \
    tar -xzvf triton.tgz && \
    rm triton.tgz

# Setup Trtis
WORKDIR /opt/tritonserver/bin

ENTRYPOINT ./tritonserver --model-repository=/models --strict-model-config=false --log-verbose=0 --min-supported-compute-capability=5.0 --backend-directory=/opt/tritonserver/backends
