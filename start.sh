#!/usr/bin/env bash
set -eo pipefail

if [ -d "/workspace" ] ; then
    mkdir -p /workspace/models/configs
    cp dlbackend/ComfyUI/_models/configs/* /workspace/models/configs/
fi

mkdir -p Data
cp Settings.fds Backends.fds Data/

exec ./launch-linux.sh --launch_mode none --host 0.0.0.0
