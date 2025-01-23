# ghcr.io/rzyns/docker-swarmui:development
FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.source=https://github.com/rzyns/docker-swarmui
LABEL org.opencontainers.image.description="SwarmUI Stable Diffusion backend and GUI"
LABEL maintainer="Janusz Dziurzyński <janusz@forserial.org>"

RUN curl -fsSL https://github.com/linkdd/procfusion/releases/download/v0.2.2/procfusion-v0.2.2-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /usr/local/bin --wildcards '*/procfusion' --strip-components=1

RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
        aria2 \
        build-essential \
        curl \
        ffmpeg \
        git \
        libatomic1 \
        libgl1 \
        libglib2.0-0 \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        python3-pip \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/tmp/git_cache <<EOF
    git clone --depth=1 https://github.com/mcmonkeyprojects/SwarmUI.git /tmp/git_cache/SwarmUI
    cp -r /tmp/git_cache/SwarmUI /SwarmUI
EOF

WORKDIR /SwarmUI

RUN <<EOF
    git config --global --add safe.directory '*'
    if [ -d Models ]; then mv Models _Models ; fi
    if [ -d Data ]; then mv Data _Data ; fi
    if [ -d .git/info ]; then echo '/start.sh' >> .git/info/exclude ; fi
EOF

WORKDIR /SwarmUI

VOLUME [ "/workspace" ]

WORKDIR /SwarmUI/dlbackend

RUN --mount=type=cache,target=/tmp/git_cache <<EOF
    git clone https://github.com/comfyanonymous/ComfyUI.git /tmp/git_cache/ComfyUI
    cp -r /tmp/git_cache/ComfyUI /SwarmUI/dlbackend/ComfyUI
EOF

WORKDIR /SwarmUI/dlbackend/ComfyUI

RUN --mount=type=cache,target=/root/.cache/pip <<EOF
    python3 -s -m venv venv
    source venv/bin/activate
    python -s -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
    python -s -m pip install -r requirements.txt
    python -s -m pip install rembg onnxruntime matplotlib opencv-python-headless imageio-ffmpeg dill ultralytics==8.1.47
EOF

WORKDIR /SwarmUI

RUN <<EOF
    mv dlbackend/ComfyUI/models dlbackend/ComfyUI/_models
    ln -s /workspace/models dlbackend/ComfyUI/models

    MODEL_DIRS="$(cat /SwarmUI/model-dirs.txt)"

    for dir in $MODEL_DIRS; do
        mkdir -p "/workspace/models/${dir}"
    done
EOF

WORKDIR /SwarmUI/dlbackend/ComfyUI

RUN --mount=type=cache,target=/tmp/git_cache <<EOF
    git clone https://github.com/ltdrdata/ComfyUI-Manager /tmp/git_cache/ComfyUI-Manager

    mkdir -p /SwarmUI/dlbackend/ComfyUI/custom_nodes
    cp -r /tmp/git_cache/ComfyUI-Manager /SwarmUI/dlbackend/ComfyUI/custom_nodes/ComfyUI-Manager
EOF

RUN --mount=type=cache,target=/root/.cache/pip <<EOF
    source venv/bin/activate
    python3 -s -m pip install -r custom_nodes/ComfyUI-Manager/requirements.txt
    python3 -s -m pip install --no-input comfy-cli
    mkdir -p /root/.config/comfy-cli
    echo "[DEFAULT]" > /root/.config/comfy-cli/config.ini
    echo "enable_tracking = True" >> /root/.config/comfy-cli/config.ini
EOF

RUN --mount=type=cache,target=/root/.cache/pip <<EOF
    source venv/bin/activate
    comfy --here node restore-snapshot /SwarmUI/snapshot.yaml
EOF

WORKDIR /SwarmUI

# COPY procfusion.toml /procfusion.toml
# COPY ./start.sh /start.sh
# COPY ./Settings.fds ./Backends.fds ./start-aria2c.sh ./snapshot.yaml /
COPY . /docker-swarmui/

# Expose the port for other containers (to use Swarm as an API if you want
EXPOSE 7801
EXPOSE 6800

# Set the run file to the launch script
# ENTRYPOINT ["bash", "./start.sh"]
ENV SWARM_ARGS=""
ENTRYPOINT [ "/usr/local/bin/procfusion", "/procfusion.toml" ]
