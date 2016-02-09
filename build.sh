#!/bin/bash
set -e

DUMB_INIT_TAG=v1.0.0
GOSU_TAG=1.7

# Get the version from the command line.
VERSION=$1
if [ -z $VERSION ]; then
    echo "Please specify a version."
    exit 1
fi

# Clear out the working folder and make the initial structure.
rm -rf pkg
mkdir -p pkg/dist
mkdir -p pkg/build
mkdir -p pkg/rootfs/bin

# Generate the tag.
if [ -z $NOTAG ]; then
  git commit --allow-empty -a --gpg-sign=348FFC4C -m "Release v$VERSION"
  git tag -a -m "Version $VERSION" -s -u 348FFC4C "v${VERSION}" master
fi

# Create the Debian build box. We don't use this to package anything
# directly, but it's used as a scratch build environment.
docker build -t hashicorp/builder-debian images/builder-debian

# Build dumb-init.
git clone https://github.com/Yelp/dumb-init.git pkg/build/dumb-init
pushd pkg/build/dumb-init
git checkout -q "tags/$DUMB_INIT_TAG"
docker run --rm -v "$(pwd):/build" -w /build hashicorp/builder-debian make
popd
cp pkg/build/dumb-init/dumb-init pkg/rootfs/bin

# Build gosu.
git clone https://github.com/tianon/gosu.git pkg/build/gosu
pushd pkg/build/gosu
git checkout -q "tags/$GOSU_TAG"
docker build --pull -t gosu .
docker run --rm gosu bash -c 'cd /go/bin && tar -c gosu*' | tar -xv
popd
cp pkg/build/gosu/gosu-amd64 pkg/rootfs/bin/gosu

# Prep the release.
pushd pkg/rootfs
zip -r ../dist/docker-base_${VERSION}_linux_amd64.zip *
popd
pushd pkg/dist
shasum -a256 * > ./docker-base_${VERSION}_SHA256SUMS
if [ -z $NOSIGN ]; then
  gpg --default-key 348FFC4C --detach-sig ./docker-base_${VERSION}_SHA256SUMS
fi
popd
