#!/usr/bin/env bash
if [ -d "/workspace" ] ; then
    if [ ! -d "/workspace/aria" ] ; then
        mkdir -p /workspace/aria
    fi

    touch /workspace/aria/aria-session.txt

    exec aria2c \
        --enable-rpc=true \
        --rpc-listen-all=true \
        --rpc-allow-origin-all=true \
        --save-session-interval=5 \
        --input-file=/workspace/aria/aria-session.txt \
        --save-session=/workspace/aria/aria-session.txt \
        --rpc-secret "${ARIA2C_SECRET:='secret'}"
else
    exec aria2c \
        --enable-rpc=true \
        --rpc-listen-all=true \
        --rpc-allow-origin-all=true \
        --rpc-secret "${ARIA2C_SECRET:='secret'}"
fi
