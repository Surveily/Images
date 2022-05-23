ARG VARIANT="3.9-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}

RUN apt-get update -q \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -yq --no-install-recommends \
    zip \
    gcc \
    git \
    unzip \
    libc-dev \
    python3-opencv \
    build-essential \
    apt-transport-https \
    ffmpeg \
    libsm6 \
    libxext6 \
    2>&1 \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --quiet --upgrade \
    pip \
    pytest-cov \
    opencv-python \
    kfp==1.8.12 \
    discord.py==1.7.3 \
    requests==2.27.1 \
    dvc==2.5.4 \
    dvc[webdav] \
    seaborn \
    pandas \
    dependency-injector \
    pycocotools \
    bokeh==2.3.2 \
    dill==0.3.4 \
    ipympl==0.7.0 \
    jupyterlab-git==0.30.1 \
    matplotlib==3.4.2 \
    scikit-image==0.18.1 \
    scikit-learn==0.24.2 \
    scipy==1.7.0 \
    xgboost==1.4.2 \
    ipywidgets==7.6.3 \
    torch==1.10.2+cpu \
    torchvision==0.11.3+cpu \
    torchaudio==0.10.2+cpu \
    -f https://download.pytorch.org/whl/cpu/torch_stable.html