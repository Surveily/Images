# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG version=3.1
ARG vsts=2.173.0
ARG powershell=18.04
FROM surveily/developer.dotnet:${version}-sdk

ARG vsts
ARG powershell

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Install Dependencies 
    apt-get install -y zip unzip build-essential gnupg-agent xorg libssl-dev libxrender-dev wget libxslt-dev libxml2-dev gdebi nodejs libc-dev libpng* gcc make autoconf libtool pkg-config nasm apt-transport-https ca-certificates curl software-properties-common libappindicator3-1 fonts-liberation libasound2 xdg-utils iputils-ping \
    # Install Java
    openjdk-8-jre openjdk-8-jdk \
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io && \
    # Install Chromium
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome.deb && \
    dpkg -i google-chrome.deb && \
    apt install -y chromium-browser && \
    rm google-chrome.deb && \
    # Install Agent
    cd /root && \
    wget https://vstsagentpackage.azureedge.net/agent/$vsts/vsts-agent-linux-x64-$vsts.tar.gz -O agent.tar.gz && \
    tar -zxvf agent.tar.gz && \
    rm agent.tar.gz && \
    # Run SSH
    mkdir ~/.ssh && \
    chmod 700 ~/.ssh && \
    ssh-keyscan -t rsa github.com gitlab.com bitbucket.org ssh.dev.azure.com vs-ssh.visualstudio.com >> ~/.ssh/known_hosts && \
    # Clean up
    ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Remember to run with -v /var/run/docker.sock:/var/run/docker.sock
COPY src/surveily.developer.dotnet.build.sh /root/entrypoint.sh
WORKDIR /root
ENTRYPOINT /root/entrypoint.sh
