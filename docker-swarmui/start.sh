#!/usr/bin/env bash
set -eo pipefail

cd /SwarmUI

if [ -d "/workspace" ] ; then
    mkdir -p /workspace/models/configs
    cp dlbackend/ComfyUI/_models/configs/* /workspace/models/configs/
fi

mkdir -p Data
[ -e "/workspace/Data/Settings.fds" ] || cp /docker-swarmui/Settings.fds /workspace/Data/
[ -e "/workspace/Data/Backends.fds" ] || cp /docker-swarmui/Backends.fds /workspace/Data/

exec ./launch-linux.sh --launch_mode none --host 0.0.0.0 --settings_file /workspace/Data/Settings.fds --backends_file /workspace/Data/Backends.fds $SWARM_ARGS
