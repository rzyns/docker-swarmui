FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.source=https://github.com/rzyns/docker-swarmui
LABEL org.opencontainers.image.description="SwarmUI Stable Diffusion backend and GUI"
LABEL maintainer="Janusz Dziurzyński <janusz@forserial.org>"

COPY procfusion.toml /procfusion.toml
RUN curl -fsSL https://github.com/linkdd/procfusion/releases/download/v0.2.2/procfusion-v0.2.2-x86_64-unknown-linux-gnu.tar.gz | tar -xz --wildcards '*/procfusion' --strip-components=1 -C /usr/local/bin

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
    mkdir dlbackend/ComfyUI/models

    MODEL_DIRS="checkpoints clip clip_vision configs controlnet diffusers diffusion_models embeddings gligen hypernetworks loras photomaker style_models text_encoders unet upscale_models vae vae_approx"

    for dir in $MODEL_DIRS; do
        mkdir -p "/workspace/Models/${dir}"
        ln -s "/workspace/Models/${dir}" "dlbackend/ComfyUI/models/"
    done
EOF

COPY ./start.sh /SwarmUI/start.sh
COPY ./Settings.fds ./Backends.fds ./start-aria2c.sh /SwarmUI/

# Expose the port for other containers (to use Swarm as an API if you want
EXPOSE 7801
EXPOSE 6800

# Set the run file to the launch script
# ENTRYPOINT ["bash", "./start.sh"]
ENTRYPOINT [ "/usr/local/bin/procfusion", "/procfusion.toml" ]
