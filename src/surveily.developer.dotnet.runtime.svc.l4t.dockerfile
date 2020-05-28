# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG download=https://download.visualstudio.microsoft.com/download/pr/da94a32f-8fa7-4df8-b54c-f3442dc2a17a/0badd31a0487b0318a3234baf023aa3c/dotnet-runtime-3.1.4-linux-arm64.tar.gz
FROM nvcr.io/nvidia/l4t-base:r32.4.2

ARG download

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Update
RUN apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install .NET
WORKDIR /dotnet
RUN wget -O dotnet.tar.gz $download && \
    tar -xvzf dotnet.tar.gz && \
    rm dotnet.tar.gz && \
    ln -s /dotnet/dotnet /usr/bin/dotnet && \
    dotnet --info