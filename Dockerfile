FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04

MAINTAINER Bianca C.

USER root

ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get update && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
       wget \
       bzip2 \
       ca-certificates \
       sudo \
       locales \
       fonts-liberation \
       git \
       build-essential \
       gcc \
       g++ \
       make \
       binutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV CONDA_DIR=/opt/anaconda \
    NB_USER=jupyternb \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Create notebook user
RUN useradd --create-home --home-dir /home/$NB_USER --shell /bin/bash $NB_USER && \
    chown $NB_USER:$NB_USER /opt

USER $NB_USER

# Install Anaconda
RUN cd /tmp && \
    wget --progress=dot:giga https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh 2>&1 && \
    bash "Anaconda2-4.2.0-Linux-x86_64.sh" -b -p $CONDA_DIR && \
    rm Anaconda2-4.2.0-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --yes bcolz && \
    $CONDA_DIR/bin/conda upgrade --all --quiet --yes

# Install theano and keras
RUN pip install \
    theano \
    keras==1.2.2

#RUN pip install keras --upgrade
#RUN pip install theano --upgrade
#RUN conda install -c mila-udem -c mila-udem/label/pre theano pygpu

USER root

# Add configuration files
ADD start-notebook.sh /usr/local/bin
ADD theanorc $HOME/.theanorc
ADD keras.json $HOME/.keras/keras.json
ADD jupyter_notebook_config.py $HOME/.jupyter/jupyter_notebook_config.py

RUN chown root:root /opt && \
    chown $NB_USER:$NB_USER $HOME/.theanorc && \
    chown -R $NB_USER:$NB_USER $HOME/.keras && \
    chown -R $NB_USER:$NB_USER $HOME/.jupyter && \
    chmod +x /usr/local/bin/start-notebook.sh

USER $NB_USER
EXPOSE 8888
WORKDIR $HOME

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]
