# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG download=https://download.visualstudio.microsoft.com/download/pr/27840e8b-d61c-472d-8e11-c16784d40091/ae9780ccda4499405cf6f0924f6f036a/dotnet-sdk-5.0.100-linux-arm64.tar.gz 
FROM nvcr.io/nvidia/l4t-base:r32.4.4

ARG download

# Settings
ENV TZ=Etc/UTC
ENV PATH /root/.yarn/bin:$PATH
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \ 
    apt-get install -y apt-transport-https ca-certificates && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install .NET
WORKDIR /dotnet
RUN wget -O dotnet.tar.gz $download && \
    tar -xvzf dotnet.tar.gz && \
    rm dotnet.tar.gz && \
    ln -s /dotnet/dotnet /usr/bin/dotnet && \
    dotnet --info

# Install Dependencies
RUN apt-get install -y build-essential xorg libssl-dev libxrender-dev wget gdebi libpng* libpng-dev gcc make autoconf libtool pkg-config nasm software-properties-common curl && \
    # Install Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    # Install Yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash
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
