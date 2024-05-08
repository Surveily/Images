FROM surveily/surveily.developer.ai.jupyter:py3.11

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
    # Install ultralytics
    ultralytics==8.0.191 \
    huggingface_hub==0.18.0

# Install basic python libraries
RUN python3 -m pip install --user --quiet --no-cache-dir \
    tqdm \
    mypy \
    black \
    scipy \
    numpy \
    mkinit\
    pandas \
    p_tqdm \
    pytest \
    seaborn \
    shapely \
    pydantic \
    fiftyone \
    openpyxl \
    ipykernel \
    papermill \
    nbconvert \
    xmltodict \
    autoflake \
    streamlit \
    pytest-cov \
    ipywidgets \
    pre-commit \
    types-tqdm \
    tensorboard \
    pytest-mock \
    distinctipy \
    pandas-stubs \
    scikit-image \
    types-PyYaml \
    types-Pillow \
    scikit-learn \
    opencv-python \
    types-requests \
    albumentations \
    types-xmltodict \
    cvat-sdk==2.11.0 \
    matplotlib==3.4.2 \
    dependency-injector \
    tensorrt==8.6.1.post1 \
    tritonclient[all]==2.41.1 \
    lightning