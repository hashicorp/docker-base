# HashiCorp Base Tool

This tool is intended to be built, signed, and checked in to the various
HashiCorp official Docker image repositories. It's used to bootstrap the
base images by providing useful functions that would otherwise be hard to
perform given the pure Dockerfile nature of official builds, and the limited
set of tools available in BusyBox.

Currently, this only knows how to fetch and verify HashiCorp releases, which
require SSL which isn't supported by the wget included with BusyBox. It's
written as a standard CLI app, though, so we may add more commands later.

We've also included a basic set of root certs required to fetch a release and
contact other APIs on hashicorp.com, such as Checkpoint. These should also be
copied into your image and stored at /system/etc/security/cacerts so that the
Go TLS library will pick them up automatically.

# Building

Docker is required for building since the Go compliling happens in a
container.

`./build.sh`

This will build and sign basetool. You could copy the binary, SHA256SUM, and
signature, and certificate files into your repository and check them in.