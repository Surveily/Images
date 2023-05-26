FROM ubuntu:22.04

ENV NB_USER jovyan
ENV NB_UID 1000
ENV NB_PREFIX /
ENV HOME /home/$NB_USER
ENV SHELL /bin/bash
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteract

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

ENV PATH="${PATH}:${HOME}/.local/bin"

ARG KUBECTL_ARCH="amd64"
ARG KUBECTL_VERSION=v1.21.0
ARG S6_ARCH="amd64"
ARG S6_VERSION=v2.2.0.3
ARG CODESERVER_VERSION=v4.11.0

SHELL ["/bin/bash", "-c"]

RUN apt-get -yq update \
    && apt-get -yq install --no-install-recommends \
    gcc \
    git \
    vim \
    zip \
    bash \
    sudo \
    wget \
    curl \
    nano \
    bzip2 \
    rsync \
    unzip \
    gnupg \
    ffmpeg \
    tzdata \
    libsm6 \
    gnupg2 \
    locales \
    libxext6 \
    libc-dev \
    python3.11 \
    python3-pip \
    lsb-release \
    iputils-ping \
    python3-opencv \
    openssh-client \
    ca-certificates \
    build-essential \
    apt-transport-https \
    software-properties-common \
    # Set default python3 version to point python3.11
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2 \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && export GNUPGHOME=/tmp/ \
    # Install s6 overlay
    && curl -sL "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}-installer" -o /tmp/s6-overlay-${S6_VERSION}-installer \
    && curl -sL "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}-installer.sig" -o /tmp/s6-overlay-${S6_VERSION}-installer.sig \
    && gpg --keyserver keys.gnupg.net --keyserver pgp.surfnet.nl --recv-keys 6101B2783B2FD161 \
    && gpg -q --verify /tmp/s6-overlay-${S6_VERSION}-installer.sig /tmp/s6-overlay-${S6_VERSION}-installer \
    && chmod +x /tmp/s6-overlay-${S6_VERSION}-installer \
    && /tmp/s6-overlay-${S6_VERSION}-installer / \
    && rm /tmp/s6-overlay-${S6_VERSION}-installer.sig /tmp/s6-overlay-${S6_VERSION}-installer \
    # Install kubectl
    && curl -sL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" -o /usr/local/bin/kubectl \
    && curl -sL "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256" -o /tmp/kubectl.sha256 \
    && echo "$(cat /tmp/kubectl.sha256) /usr/local/bin/kubectl" | sha256sum --check \
    && rm /tmp/kubectl.sha256 \
    && chmod +x /usr/local/bin/kubectl \
    # Install code-server
    && curl -sL "https://github.com/cdr/code-server/releases/download/${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION/v/}_amd64.deb" -o /tmp/code-server.deb \
    && dpkg -i /tmp/code-server.deb \
    && rm -f /tmp/code-server.deb \
    # Install code-server extensions
    && code-server --install-extension \
    ms-python.isort \
    ms-toolsai.jupyter \
    ms-toolsai.jupyter-renderers \
    ms-python.vscode-pylance \
    ms-python.python \
    ms-azuretools.vscode-docker \
    streetsidesoftware.code-spell-checker \
    # create user and set required ownership
    && useradd -M -s /bin/bash -N -u ${NB_UID} ${NB_USER} \
    && usermod -aG sudo ${NB_USER} \
    && mkdir -p ${HOME} \
    && chown -R ${NB_USER}:users ${HOME} \
    && chown -R ${NB_USER}:users /usr/local/bin \
    && chown -R ${NB_USER}:users /etc/s6 \
    # Setup home folder for kubeflow, see ./s6/cont-init.d/01-copy-tmp-home
    && mkdir -p /tmp_home \
    && cp -r ${HOME} /tmp_home \
    && chown -R ${NB_USER}:users /tmp_home \
    # Allow sudo to jovyan to install additional packages
    && echo "${NB_USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${NB_USER}

COPY --chown=jovyan:users s6/ /etc

USER $NB_UID

# Install Python packages
RUN python3 -m pip install -U pip && \
    python3 -m pip install --user --quiet --no-cache-dir \
    # Install pyTorch 2.0
    torch==2.0.0 \
    torchvision==0.15.1 \
    # Install basic python libraries
    tqdm \
    scipy \
    numpy \
    pandas \
    pytest \
    seaborn \
    xmltodict \
    openpyxl \
    ipykernel \
    pytest-cov \
    ipywidgets \
    matplotlib \
    tensorboard \
    scikit-image \
    scikit-learn \
    opencv-python \
    albumentations \
    dependency-injector

EXPOSE 8888

ENTRYPOINT ["/init"]
