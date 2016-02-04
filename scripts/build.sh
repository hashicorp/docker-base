#!/bin/bash
set -e

DNSMASQ_TAG=v2.75
DUMB_INIT_TAG=v1.0.0
GOSU_TAG=1.7

# Run from the parent directory of the script.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$(cd -P "$(dirname "$SOURCE")/.." && pwd)"
cd $DIR

# Clear out the working folder and make the initial structure.
rm -rf pkg
mkdir -p pkg/build
mkdir -p pkg/rootfs/bin

# Create the Debian build box. We don't use this to package anything
# directly, but it's used as a scratch build environment.
docker build -t hashicorp/builder-debian images/builder-debian

# Build dnsmasq.
git clone git://thekelleys.org.uk/dnsmasq.git pkg/build/dnsmasq
pushd pkg/build/dnsmasq
git checkout -q "tags/$DNSMASQ_TAG"
docker run --rm -v "$(pwd):/build" -w /build hashicorp/builder-debian make
popd
cp pkg/build/dnsmasq/src/dnsmasq pkg/rootfs/bin

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

# SHA and optionally sign the rootfs contents that we provided. We
# sign each binary piece-wise since images won't contain all of
# them.
pushd pkg/rootfs/bin
find . -type f -exec sh -c 'shasum -a256 $(basename $1) >$1.SHA256SUM' -- {} \;
if [ -z $NOSIGN ]; then
    gpg --default-key 348FFC4C --detach-sig *.SHA256SUM
fi
popd

# Build an image, injecting the rootfs content we built above into the
# Docker context so it can be pulled into the image (the various images
# still get to decide what they include).
build_image()
{
    image="$1"
    cp -r "$image" pkg/build
    image=$(basename "$image")
    cp -r pkg/rootfs "pkg/build/$image"
    docker build -t "hashicorp/$image" "pkg/build/$image"
}

# Build the base images first. These aren't allowed to depend on
# each other.
for base in images/base-*; do
    build_image "$base"
done

# Build the app images second, since these rely on the base images.
for app in images/app-base-*; do
    build_image "$app"
done
