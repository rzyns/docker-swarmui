#!/usr/bin/env bash
set -eo pipefail

if [ -d "/workspace" ] && [ ! -d "/workspace/dlbackend" ]; then
    echo "Installing comfy"
    cd /workspace
    bash -eo pipefail /SwarmUI/launchtools/comfy-install-linux.sh nv
    mv dlbackend/ComfyUI/models dlbackend/ComfyUI/_models
    mkdir dlbackend/ComfyUI/models
    mv dlbackend/ComfyUI/_models/config dlbackend/ComfyUI/

    MODEL_DIRS="checkpoints clip clip_vision config controlnet diffusers diffusion_models embeddings gligen hypernetworks loras photomaker style_models text_encoders unet upscale_models vae vae_approx"

    if [ ! -d "/workspace/Models/config" ]; then
        mv dlbackend/ComfyUI/_models/config /workspace/Models/
        mkdir /workspace/Models
    fi

    for dir in $MODEL_DIRS; do
        mkdir -p "/workspace/Models/${dir}"
        ln -s "/workspace/Models/${dir}" "dlbackend/ComfyUI/models/"
    done

    cd /SwarmUI
fi

mkdir -p Data
cp Settings.fds Backends.fds Data/

exec ./launch-linux.sh --launch_mode none --host 0.0.0.0
