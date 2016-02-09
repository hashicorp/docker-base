# HashiCorp Docker Image Tools

This repository contains tools used to build official HashiCorp Docker images,
and common tools that run inside these images. See the README files in each
directory for more details. Here's a summary:

* basetool: This is a simple Go binary that helps fetch and verify files from
  the HashiCorp releaseses server from inside a limited BusyBox (or even scratch)
  image. This is intended to be built and checked in to your official repo build,
  and doesn't actually end up in the container. It should almost never change so
  this won't be a huge hassle to maintain.
* rootfs: This is a collection of files we actually package inside containers.
  Some containers may tailor this a bit, but this is a basic set of things for
  zombie process reaping, managing which user we run as, root certificates, etc.
