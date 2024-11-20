ARG PY_VERSION=3.11
FROM mcr.microsoft.com/devcontainers/python:${PY_VERSION}

USER root

RUN usermod -u 1001 vscode && \
    groupmod -g 1001 vscode

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
    lsb-release \
    iputils-ping \
    python3-opencv \
    openssh-client \
    ca-certificates \
    build-essential \
    apt-transport-https \
    software-properties-common \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && export GNUPGHOME=/tmp/

USER vscode

# WARNING!
# Change ultralytics version with great care, due
# to different problems:
# - DDP
# - DDP logging callbacks
# - Runtime parameters
RUN python3 -m pip install -U pip && \
    python3 -m pip install --user --quiet --no-cache-dir \
    torch==2.5.1 \
    torchvision==0.20.1 \
    ultralytics==8.3.34 \
    huggingface_hub==0.18.0

RUN python3 -m pip install --user --quiet --no-cache-dir \
    minio \
    mlflow \
    apache-airflow \
    apache-airflow-providers-cncf-kubernetes

RUN python3 -m pip install --user --quiet --no-cache-dir \
    flytekit \
    flytekitplugins-pod \
    flytekitplugins-omegaconf

    RUN python3 -m pip install --user --quiet --no-cache-dir \
    tqdm \
    ruff \
    mypy \
    black \
    scipy \
    numpy \
    mkinit\
    pandas \
    pynvml \
    p_tqdm \
    pytest \
    plotly \
    seaborn \
    shapely \
    openpyxl \
    ipykernel \
    papermill \
    nbconvert \
    xmltodict \
    autoflake \
    lightning==2.4.0 \
    streamlit \
    pytest-cov \
    ipywidgets \
    pre-commit \
    types-tqdm \
    hydra-core \
    tensorboard \
    pytest-mock \
    distinctipy \
    pandas-stubs \
    scikit-image \
    types-PyYaml \
    types-Pillow \
    scikit-learn \
    python-dotenv \
    opencv-python \
    types-requests \
    albumentations \
    types-xmltodict \
    pydantic==2.6.0 \
    cvat-sdk==2.11.0 \
    matplotlib==3.4.2 \
    dependency-injector \
    tensorrt==8.6.1.post1 \
    tritonclient[all]==2.41.1 \
    aiofile==3.8.8 \
    aiofiles==23.2.1 \
    aiobotocore==2.13.0 \