#!/bin/bash
set -e

# Note the hashes here are the git SHAs that correspond to the given tags. This
# lets us make sure the tags don't change on us.
DUMB_INIT_TAG=v1.0.0
DUMB_INIT_HASH=a9eadb580c0d234fc4090c1bf3f19f8d87bff76b
GOSU_TAG=1.7
GOSU_HASH=6908f86c7e0bf676b27b9237c41ca40719d4b9cb

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
if $(git show-ref --verify refs/tags/${DUMB_INIT_TAG} | grep --quiet "$DUMB_INIT_HASH") ; then
    echo "Verified dumb-init git repository state"
else
    echo "Could not verify dumb-init git repository state"
    exit 1
fi
docker run --rm -v "$(pwd):/build" -w /build hashicorp/builder-debian make
popd
cp pkg/build/dumb-init/dumb-init pkg/rootfs/bin

# Build gosu.
git clone https://github.com/tianon/gosu.git pkg/build/gosu
pushd pkg/build/gosu
git checkout -q "tags/$GOSU_TAG"
if $(git show-ref --verify refs/tags/${GOSU_TAG} | grep --quiet "$GOSU_HASH") ; then
    echo "Verified gosu git repository state"
else
    echo "Could not verify gosu git repository state"
    exit 1
fi
docker build --no-cache --pull -t gosu .
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
