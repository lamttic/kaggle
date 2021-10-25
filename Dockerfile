# We use docker image provided by nvidia.
# These images below contain cuda, a parallel computing platform and API model, cudnn, a GPU-accelerated library for dnn.

# Builds on the base and includes the CUDA math libraries, and NCCL. A runtime image that also includes cuDNN is available.
# Note that cuda 11.1 is required for pytorch 1.9.0
FROM nvidia/cuda:11.1-cudnn8-runtime-ubuntu18.04 AS base

ARG PYTHON=3.7

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8
ENV PATH=/root/.local/bin:$PATH

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

COPY clean.sh .
RUN chmod 0755 ./clean.sh

# Install system packages (python, common-packages, and so on..)
RUN apt update && \
    apt install -y --no-install-recommends --allow-change-held-packages \
    libsndfile1 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libopenblas-dev \
    python${PYTHON} python${PYTHON}-dev python${PYTHON}-distutils \
    vim git wget gcc sudo curl g++ make && \
    ./clean.sh

# Set python3 as a default and upgrade pip
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON} 1 && \
    update-alternatives --set python3 /usr/bin/python${PYTHON} && \
    curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py --force-reinstall && \
    python3 -m pip install --upgrade pip && \
    ./clean.sh

# Install rubik-cube requirements
COPY requirements.txt .

RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    ./clean.sh
RUN python3 -m pip install --no-cache-dir torch==1.9.1+cu111 torchvision==0.10.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html && \
    ./clean.sh

# Clean up
RUN rm ./clean.sh ./requirements.txt ./get-pip.py

# Install gsutil for getting dataset
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
        sudo apt-get install apt-transport-https ca-certificates gnupg -y && \
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
        sudo apt-get update && sudo apt-get install google-cloud-sdk -y

# Install jupyter
RUN pip3 install jupyter && jupyter notebook --generate-config && echo c.NotebookApp.ip = \'\*\' >> ~/.jupyter/jupyter_notebook_config.py

COPY . /kaggle
WORKDIR /kaggle
