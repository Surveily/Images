# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG download=https://download.visualstudio.microsoft.com/download/pr/ac555882-afa3-4f5b-842b-c4cec2ae0e90/84cdd6d47a9f79b6722f0e0a9b258888/aspnetcore-runtime-5.0.0-linux-arm64.tar.gz 
FROM nvcr.io/nvidia/deepstream-l4t:5.0.1-20.09-base

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