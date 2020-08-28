# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG version=3.1
ARG vsts=2.173.0
ARG powershell=18.04
ARG helm=v2.16.10-linux-amd64
FROM surveily/developer.dotnet:${version}-sdk

ARG helm
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
    # Install Fastlane
    ruby ruby-dev ruby-bundler && \
    gem install pkg-config && \
    gem install bundler && \
    gem install nokogiri -- --use-system-libraries --with-xml2-include=/usr/include/libxml2 --with-xml2-lib=/usr/lib && \
    #cat /var/lib/gems/2.5.0/extensions/x86_64-linux/2.5.0/nokogiri-1.10.2/mkmf.log
    gem install fastlane -NV && \
    # Install React Native CLI
    npm install -g react-native-cli && \
    # Install Android Studio
    # cd /opt && \
    # wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip -O sdk-tools-linux.zip && \
    # unzip sdk-tools-linux.zip -d android-sdk-linux  && \
    # rm sdk-tools-linux.zip && \
    # cd / && \
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
    # Install Kubectl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    # Install Helm
    wget https://storage.googleapis.com/kubernetes-helm/helm-$helm.tar.gz -O helm.tar.gz && \
    tar -zxvf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm && \
    helm init --client-only && \
    # Install Appium
    npm install -g appium --unsafe-perm=true --allow-root && \
    APPIUM=1 && \
    # Install Agent
    cd /root && \
    wget https://vstsagentpackage.azureedge.net/agent/$vsts/vsts-agent-linux-x64-$vsts.tar.gz -O agent.tar.gz && \
    tar -zxvf agent.tar.gz && \
    rm agent.tar.gz && \
    # Run SSH
    mkdir ~/.ssh && \
    chmod 700 ~/.ssh && \
    ssh-keyscan -t rsa ssh.dev.azure.com >> ~/.ssh/known_hosts && \
    ssh-keyscan -t rsa vs-ssh.visualstudio.com >> ~/.ssh/known_hosts && \
    # Clean up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Configure Android Studio
# ENV ANDROID_HOME=/opt/android-sdk-linux
# ENV PATH="${PATH}:${ANDROID_HOME}/tools"
# ENV PATH="${PATH}:${ANDROID_HOME}/tools/bin"

# WORKDIR /opt/android-sdk-linux
# RUN tools/bin/sdkmanager --update && \
#     yes | tools/bin/sdkmanager --licenses && \
#     tools/bin/sdkmanager "platform-tools" "platforms;android-28" "build-tools;28.0.3" "sources;android-28" "system-images;android-25;google_apis;arm64-v8a" "emulator" && \
#     echo no | avdmanager create avd -n android-25 -k "system-images;android-25;google_apis;arm64-v8a" -b google_apis/arm64-v8a --force

# Remember to run with -v /var/run/docker.sock:/var/run/docker.sock
COPY src/surveily.developer.dotnet.build.sh /root/entrypoint.sh
WORKDIR /root
ENTRYPOINT /root/entrypoint.sh
