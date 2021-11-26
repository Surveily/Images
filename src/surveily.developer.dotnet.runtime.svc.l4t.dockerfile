# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG download=https://download.visualstudio.microsoft.com/download/pr/4b114207-eaa2-40fe-8524-bd3c56b2fd9a/1d74fdea8701948c0150c39645455b2f/dotnet-runtime-5.0.0-linux-arm64.tar.gz 
#FROM nvcr.io/nvidia/deepstream-l4t:6.0-base
FROM nvcr.io/nvidia/l4t-base:r32.6.1

ARG download

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Update
RUN apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Update CA
    update-ca-certificates -f

# Install .NET
WORKDIR /dotnet
RUN wget -O dotnet.tar.gz $download && \
    tar -xvzf dotnet.tar.gz && \
    rm dotnet.tar.gz && \
    ln -s /dotnet/dotnet /usr/bin/dotnet && \
    dotnet --info