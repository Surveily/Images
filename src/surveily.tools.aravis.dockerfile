# Article: https://gist.github.com/nitheeshkl/5cbf1a0777801a7e9b8e12f8252d465e
# Docker Mod: `xhost +"local:docker@"`
# Docker Run: `docker run -it --privileged --rm --net host -e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /tmp/dbus-MIcovvTWvG:/tmp/dbus-MIcovvTWvG aravis`

FROM ubuntu:latest

WORKDIR /

# Update & Upgrade
ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y

# Install Dependencies (x11-apps optionally for x11 redirect)
RUN apt-get install -y git build-essential libgtk-3-dev automake autoconf libtool intltool x11-apps

# Install GST
RUN apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio libgstreamer-plugins-base1.0-dev

# Clone Aravis
ADD https://download.gnome.org/sources/aravis/0.6/aravis-0.6.4.tar.xz aravis.tar.xz
RUN tar -xf aravis.tar.xz && rm aravis.tar.xz

WORKDIR /aravis-0.6.4

# Install Aravis Dependencies
RUN apt-get install -y libxml++2.6-dev libusb-1.0-0-dev libnotify-dev libaudit-dev libaudit1

RUN ./configure --enable-usb --enable-packet-socket --enable-viewer --enable-gst-plugin --enable-zlib-pc --enable-fast-heartbeat --enable-cpp-test
RUN make
RUN make install

# Clean up
RUN ldconfig && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
