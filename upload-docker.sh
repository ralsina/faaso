#!/bin/sh
pass github-registry | docker login ghcr.io -u ralsina --password-stdin
docker run --rm --privileged \
        multiarch/qemu-user-static \
        --reset -p yes
docker build . --platform=linux/arm64 -t ghcr.io/ralsina/faaso-arm64:latest --push
docker build . --platform=linux/amd64 -t ghcr.io/ralsina/faaso:latest --push
