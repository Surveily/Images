FROM jupyter/base-notebook:notebook-6.5.4

ENV DEBIAN_FRONTEND noninteract

ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

ENV NB_UID 1000
ENV NB_USER jovyan

USER root

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
    && conda install -yq python=3.11 \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && export GNUPGHOME=/tmp/ \
    # Allow sudo to jovyan to install additional packages
    && echo "${NB_USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${NB_USER}

USER ${NB_UID}

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
    nbconvert \
    pytest-cov \
    ipywidgets \
    matplotlib \
    tensorboard \
    scikit-image \
    scikit-learn \
    opencv-python \
    albumentations \
    dependency-injector

COPY start-notebook-frozen.sh /usr/local/bin/

CMD [ "start-notebook-frozen.sh" ]