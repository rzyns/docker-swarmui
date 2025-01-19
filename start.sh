#!/usr/bin/env bash
if [ ! -d "./dlbackend/comfy/ComfyUI" ]; then
    ./launchtools/comfy-install-linux.sh nv
fi

exec ./launch-linux.sh --launch_mode none --host 0.0.0.0
