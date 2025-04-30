# Copyright (c) Surveily sp. z o.o. All rights reserved.
# Remember to run with -v /var/run/docker.sock:/var/run/docker.sock

FROM ubuntu:bionic

# Settings
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

# Update
RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && \
    # Apply Timezone
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Install Dependencies
    apt-get install -y \
    libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio \
    python3-pip && \
    ffmpeg && \
    # Clean up
    ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install tqdm requests dataclasses
