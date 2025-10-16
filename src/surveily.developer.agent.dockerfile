# Based on https://github.com/emberstack/docker-azure-pipelines-agent/blob/main/src/docker/Dockerfile
FROM ubuntu:noble

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
ENV AGENT_ALLOW_RUNASROOT="true"
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  jq \
  git \
  libicu74 \
  iputils-ping \
  libcurl4 \
  libunwind8 \
  libssl1.0 \
  zip \
  unzip \
  ssh \
  sshpass \
  smbclient \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.ssh && \
  chmod 700 ~/.ssh && \
  ssh-keyscan -t rsa github.com gitlab.com bitbucket.org ssh.dev.azure.com vs-ssh.visualstudio.com >> ~/.ssh/known_hosts

# Install Azure CLI
RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash

# Install Docker
RUN curl https://get.docker.com | sh

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Clean up
RUN ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /azp

COPY src/surveily.developer.agent.sh .
RUN chmod +x surveily.developer.agent.sh

CMD ["./surveily.developer.agent.sh"]
