FROM cr.flyte.org/flyteorg/flytekit:py3.11-1.13.8

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
    lsb-release \
    iputils-ping \
    python3-opencv \
    openssh-client \
    ca-certificates \
    build-essential \
    apt-transport-https \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && export GNUPGHOME=/tmp/

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
    imagehash \
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
    cvat-sdk==2.21 \
    matplotlib==3.9.2 \
    dependency-injector \
    tensorrt==8.6.1.post1 \
    tritonclient[all]==2.41.1 \
    aiofile==3.8.8 \
    aiofiles==23.2.1 \
    aiobotocore==2.13.0 \
    numba==0.61.0 \
    decord==0.6.0 \