#!/bin/bash

set -e

docker run --rm --privileged \
  multiarch/qemu-user-static \
  --reset -p yes

# Build for AMD64
docker build . -f Dockerfile.static -t faaso-builder
docker run -ti --rm -v "$PWD":/app --user="$UID" faaso-builder /bin/sh -c "cd /app && rm -rf lib shard.lock && make static"
mv bin/faaso bin/faaso-static-linux-amd64

# Build for ARM64
docker build . -f Dockerfile.static --platform linux/arm64 -t faaso-builder
docker run -ti --rm -v "$PWD":/app --platform linux/arm64 --user="$UID" faaso-builder /bin/sh -c "cd /app && rm -rf lib shard.lock && make static"
mv bin/faaso bin/faaso-static-linux-arm64
