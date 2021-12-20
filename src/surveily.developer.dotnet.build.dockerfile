FROM ubuntu:21.10

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get upgrade -y \
&& apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        git \
        iputils-ping \
        libcurl4 \
        libunwind8 \
        netcat \
        libssl1.0 \
		zip \
		unzip \
        ssh\
&& rm -rf /var/lib/apt/lists/*

RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

RUN curl https://get.docker.com | sh \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.ssh && \
    chmod 700 ~/.ssh && \
    ssh-keyscan -t rsa github.com gitlab.com bitbucket.org ssh.dev.azure.com vs-ssh.visualstudio.com >> ~/.ssh/known_hosts

WORKDIR /azp

COPY src/surveily.developer.dotnet.build.sh .
RUN chmod +x surveily.developer.dotnet.build.sh

CMD ["./surveily.developer.dotnet.build.sh"]