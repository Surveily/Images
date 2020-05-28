# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG download=https://download.visualstudio.microsoft.com/download/pr/e5e70860-a6d4-48cf-b0d1-eeba32657d80/2da3c605aaa65c7e4ac2ad0507a2e429/dotnet-sdk-3.1.300-linux-arm64.tar.gz
FROM nvcr.io/nvidia/l4t-base:r32.4.2

ARG download

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install .NET
WORKDIR /dotnet
RUN wget -O dotnet.tar.gz $download && \
    tar -xvzf dotnet.tar.gz && \
    rm dotnet.tar.gz && \
    ln -s /dotnet/dotnet /usr/bin/dotnet && \
    dotnet --info

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Install Dependencies
    apt-get install -y build-essential xorg libssl-dev libxrender-dev wget gdebi libpng* libpng-dev gcc make autoconf libtool pkg-config nasm software-properties-common curl && \
    # Install Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    # Install Yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
    # Install Chromium
    # wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    # apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    # rm google-chrome-stable_current_amd64.deb && \
    # Install Powershell
    # wget -q https://packages.microsoft.com/config/ubuntu/$powershell/packages-microsoft-prod.deb && \
    # dpkg -i packages-microsoft-prod.deb && \
    # apt-get update && \
    # add-apt-repository universe && \
    # apt-get install -y powershell && \
    # rm packages-microsoft-prod.deb && \
    # Clean up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

ENV PATH /root/.yarn/bin:$PATH