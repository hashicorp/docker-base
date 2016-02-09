# HashiCorp Base Image Root Filesystem

This folder contains some scripts used to build and release a root filesystem to
include in official HashiCorp base images. The contents of this can be fetched
and merged into a container build in order to provide useful utilities:

* [dumb-init](https://github.com/Yelp/dumb-init), which makes it easy to configure child process reaping and gives us signal forwarding to all processes running under it
* [gosu](https://github.com/tianon/gosu), which makes it less of a pain to switch to other users without introducing a `su` or `sudo` intermediate process

Containers may tailor what they include depending on what they need.

# Building

Docker is required for building since compiling steps happen in containers.

`./build.sh`

This will build the rootfs, sign the binaries, compress everything, and then
release it using the hc-releases tool.