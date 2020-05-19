# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG version=3.1
ARG system=bionic
ARG powershell=18.04
FROM mcr.microsoft.com/dotnet/core/sdk:${version}-${system}

# Set Timezone
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y keyboard-configuration && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Install Dependencies
    apt-get install -y build-essential xorg libssl-dev libxrender-dev wget gdebi libpng* gcc make autoconf libtool pkg-config nasm software-properties-common && \
    # Install Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    # Install Yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
    # Install Chromium
    apt-get install -y chromium-browser libpng-dev && \
    # Install Powershell
    wget -q https://packages.microsoft.com/config/ubuntu/${powershell}/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    add-apt-repository universe && \
    apt-get install -y powershell && \
    rm packages-microsoft-prod.deb && \
    # Clean up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

ENV PATH /root/.yarn/bin:$PATH
