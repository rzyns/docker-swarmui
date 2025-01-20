#!/usr/bin/env bash
set -eo pipefail

if [ ! -d "./dlbackend" ]; then
    bash -eo pipefail ./launchtools/comfy-install-linux.sh nv
    if [ -d "/workspaces" ] && [ ! -d "/workspaces/dlbackend" ]; then
        mv ./dlbackend /workspaces/
        ln -s /workspaces/dlbackend ./dlbackend
    fi
fi

exec ./launch-linux.sh --launch_mode web --host 0.0.0.0
