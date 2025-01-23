#!/usr/bin/env bash
if [ -d "/workspace" ] ; then
    touch /workspace/aria-session.txt
    aria2c \
        --enable-rpc=true \
        --rpc-listen-all=true \
        --rpc-allow-origin-all=true \
        --save-session-interval=5 \
        --input-file=/workspace/aria-session.txt \
        --save-session=/workspace/aria-session.txt \
        --rpc-secret "${ARIA2C_SECRET:='secret'}"
else
    aria2c \
        --enable-rpc=true \
        --rpc-listen-all=true \
        --rpc-allow-origin-all=true \
        --rpc-secret "${ARIA2C_SECRET:='secret'}"
fi
