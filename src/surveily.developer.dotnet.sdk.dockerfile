# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG version=3.1
ARG system=bionic
ARG powershell=18.04
ARG image=core/sdk
FROM mcr.microsoft.com/dotnet/${image}:${version}-${system}

ARG system
ARG version
ARG powershell

# Settings
ENV TZ=Etc/UTC
ENV PATH /root/.yarn/bin:$PATH
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Installation
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Upgrade
    apt-get update && apt-get upgrade -y && \
    # Install Dependencies
    apt-get install -y apt-transport-https gnupg2 vim build-essential xorg libssl-dev libxrender-dev wget gdebi libpng* libpng-dev gcc make autoconf libtool pkg-config nasm software-properties-common && \
    # Add Sources    
    curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    # Install Kubectl
    apt-get install -y kubectl && \
    # Install Helm
    apt-get install -y helm && \
    # Install Node
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    # Install Yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
    # Install Powershell
    #   wget -q https://packages.microsoft.com/config/ubuntu/$powershell/packages-microsoft-prod.deb && \
    #   dpkg -i packages-microsoft-prod.deb && \
    #   apt-get update && \
    #   add-apt-repository universe && \
    #   apt-get install -y powershell && \
    #   rm packages-microsoft-prod.deb && \
    # Clean up
    ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
