FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.source=https://github.com/rzyns/docker-swarmui
LABEL org.opencontainers.image.description="SwarmUI Stable Diffusion backend and GUI"
LABEL maintainer="Janusz Dziurzyński <janusz@forserial.org>"

# Dotnet env stuff
ENV \
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    DOTNET_NOLOGO=true \
    DOTNET_SDK_VERSION=8.0.405 \
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    NUGET_XMLDOC_MODE=skip \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Ubuntu-24.04

RUN <<EOF
    apt-get update
    apt-get install -y --no-install-recommends \
        aria2 \
        build-essential \
        curl \
        dotnet-sdk-8.0 \
        ffmpeg \
        git \
        libatomic1 \
        libgl1 \
        libglib2.0-0 \
        python3.11 \
        python3.11-dev \
        python3.11-venv \
        wget

    rm -rf /var/lib/apt/lists/*
EOF

# Install PowerShell global tool
RUN <<EOF
    powershell_version=7.4.6
    curl -fSL --output PowerShell.Linux.x64.$powershell_version.nupkg https://powershellinfraartifacts-gkhedzdeaghdezhr.z01.azurefd.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg
    powershell_sha512='676a69c7a0b03c6a2397a253ce54cb76857d4ddd252f9da7d9fc3d1cb7a62386316b73bd87519061f799fee60cbc39831060b263ebe0f200879c1524e8aea00d'
    echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c -
    mkdir -p /usr/share/powershell
    dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.x64
    dotnet nuget locals all --clear
    rm PowerShell.Linux.x64.$powershell_version.nupkg
    ln -s /usr/share/powershell/pwsh /usr/bin/pwsh
    chmod 755 /usr/share/powershell/pwsh

    # To reduce image size, remove the copy nupkg that nuget keeps.
    find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm
EOF

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

RUN --mount=type=cache,target=/root/.cache/pip python3.11 -s -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
RUN --mount=type=cache,target=/root/.cache/pip python3.11 -s -m pip install -r requirements.txt

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
COPY ./comfy-install-linux.sh /SwarmUI/launchtools/

# Expose the port for other containers (to use Swarm as an API if you want
EXPOSE 7801
EXPOSE 6800

# Set the run file to the launch script
ENTRYPOINT ["bash", "./start.sh"]
