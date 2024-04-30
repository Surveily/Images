ARG PY_VERSION=3.11
FROM mcr.microsoft.com/devcontainers/python:${PY_VERSION}

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Configure environment variables
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV HOME="/home/${NB_USER}"
ENV DEBIAN_FRONTEND noninteract
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

ENV PATH /home/${NB_USER}/.local/bin:$PATH

# Rename vscode user to ${NB_USER} (jovyan)
RUN usermod -l ${NB_USER} vscode \
    && usermod -d /home/${NB_USER} -m ${NB_USER} \
    && chown -R ${NB_USER}:${NB_GID} /home/${NB_USER}

RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    bzip2 \
    ca-certificates \
    locales \
    sudo \
    tini \
    nodejs \
    npm \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Copy a script to fix permissions
COPY fix-permissions.sh /usr/local/bin/fix-permissions.sh
RUN chmod a+rx /usr/local/bin/fix-permissions.sh

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    chmod g+w /etc/passwd && \
    fix-permissions.sh "${HOME}"

USER ${NB_UID}

# Install jupyter
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install \
    notebook \
    jupyterhub \
    jupyterlab && \
    jupyter notebook --generate-config && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions.sh "/home/${NB_USER}"

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

ENTRYPOINT [ "tini", "-g", "--" ]

CMD [ "start-notebook.sh" ]

USER root

COPY start.sh start-notebook.sh /usr/local/bin/
COPY jupyter_server_config.py /etc/jupyter/
RUN chmod a+rx /usr/local/bin/start.sh /usr/local/bin/start-notebook.sh

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions.sh /etc/jupyter/

USER ${NB_UID}

WORKDIR "${HOME}"