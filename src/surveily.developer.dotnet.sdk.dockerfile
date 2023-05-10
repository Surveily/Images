# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG system=focal
ARG version=5.0
ARG powershell=18.04
ARG image=core/sdk
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:${version}-${system}

ARG powershell
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV PATH=/root/.yarn/bin:/home/vscode/.dotnet/tools:$PATH

RUN groupadd -f --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} || true && \
    # Installation
    sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Add GPG keys
    mkdir -m 0755 -p /etc/apt/keyrings && \
    curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    # Setup repositories
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Upgrade
    apt-get update && apt-get upgrade -y && apt-get install -y software-properties-common && \
    # Init PPAs
    add-apt-repository ppa:git-core/ppa -y && \
    # Install Dependencies
    apt-get update && apt-get install -y ssh apt-transport-https ca-certificates gnupg2 gnupg-agent vim build-essential xorg libssl-dev libxrender-dev wget gdebi libpng* libpng-dev gcc make autoconf libtool pkg-config nasm software-properties-common default-jre-headless git && \
    # Install Docker
    apt-get install -y docker-ce docker-ce-cli containerd.io && \
    # Install Kubectl
    apt-get install -y kubectl && \
    # Install Helm
    apt-get install -y helm && \
    # Install Node
    curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
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
    # Install Frontend Test
    wget --no-verbose -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get install -y /tmp/chrome.deb && \
    rm /tmp/chrome.deb && \
    # Clean up
    ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
