#!/bin/bash
set e

export PKGNAME=$(basename "$PWD")
export VERSION=$(git cliff --bumped-version --unreleased |cut -dv -f2)

sed "s/^version:.*$/version: $VERSION/g" -i shard.yml
git add shard.yml
git cliff --bump -u -p CHANGELOG.md
git commit -a -m "bump: Release v$VERSION"
./build_static.sh
git tag "v$VERSION"
git push --tags
gh release create "v$VERSION" "bin/$PKGNAME-static-linux-amd64" "bin/$PKGNAME-static-linux-arm64" --title "Release v$VERSION" --notes "$(git cliff -l -s all)"
./upload-docker.sh
