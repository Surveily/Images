# Copyright (c) Surveily sp. z o.o. All rights reserved.

ARG version=3.1
ARG system=bionic
ARG image=core/aspnet
FROM mcr.microsoft.com/dotnet/${image}:${version}-${system}

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Install Dependencies
    apt-get install -y build-essential xorg libssl-dev libxrender-dev wget gdebi && \
    # Clean up
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
