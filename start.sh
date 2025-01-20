#!/usr/bin/env bash
set -eo pipefail

if [ ! -d "./dlbackend" ]; then
    ./launchtools/comfy-install-linux.sh nv
fi

exec ./launch-linux.sh --launch_mode web --host 0.0.0.0
