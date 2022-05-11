# Article: https://gist.github.com/nitheeshkl/5cbf1a0777801a7e9b8e12f8252d465e
# Docker Mod: `xhost +"local:docker@"`
# Docker Run: `docker run -it --privileged --rm --net host -e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp/dbus-MIcovvTWvG:/tmp/dbus-MIcovvTWvG aravis`

FROM ubuntu:focal

WORKDIR /

# Update & Upgrade
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

RUN apt-get update && apt-get install -y python3 python3-pip

RUN python3 -m pip install meson
RUN python3 -m pip install ninja

# Install Dependencies (x11-apps optionally for x11 redirect)
RUN apt-get update && apt-get install -y git build-essential libgtk-3-dev x11-apps

# Install GST
RUN apt-get update && apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio libgstreamer-plugins-base1.0-dev

# Clone Aravis
ADD https://github.com/AravisProject/aravis/releases/download/0.8.21/aravis-0.8.21.tar.xz aravis.tar.xz
RUN tar -xf aravis.tar.xz && rm aravis.tar.xz

WORKDIR /aravis-0.8.21

# Install Aravis Dependencies
RUN apt-get update && apt-get install -y libxml2-dev libglib2.0-dev cmake libusb-1.0-0-dev gobject-introspection libgtk-3-dev gtk-doc-tools  xsltproc libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev libgirepository1.0-dev gettext

RUN sed 's/2000000/3600000000/g' gst/gstaravis.c > gst/gstaravis.c.new && rm gst/gstaravis.c && mv gst/gstaravis.c.new gst/gstaravis.c
RUN meson build

WORKDIR /aravis-0.8.21/build

RUN ninja
RUN ninja install

# Copy GST Plugin
RUN cp gst/libgstaravis.0.8.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/

# Clean up
RUN ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
