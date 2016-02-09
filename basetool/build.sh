#!/bin/bash
set -e

# Build a release of the basetool in a hermetic Go build container.
docker run --rm -v "$PWD":/usr/src/basetool -w /usr/src/basetool \
       golang:latest sh -c "go get -d -v && go build"

# Sign the binary.
find basetool -type f -exec sh -c 'shasum -a256 $(basename $1) >$1.SHA256SUM' -- {} \;
if [ -z $NOSIGN ]; then
    gpg --default-key 348FFC4C --detach-sig *.SHA256SUM
fi
