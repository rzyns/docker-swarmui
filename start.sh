#!/usr/bin/env bash
set -eo pipefail

cd /SwarmUI

if [ -d "/workspace" ] ; then
    mkdir -p /workspace/models/configs
    cp dlbackend/ComfyUI/_models/configs/* /workspace/models/configs/
fi

mkdir -p Data
cp /docker-swarmui/Settings.fds /docker-swarmui/Backends.fds Data/

exec ./launch-linux.sh --launch_mode none --host 0.0.0.0 $SWARM_ARGS
