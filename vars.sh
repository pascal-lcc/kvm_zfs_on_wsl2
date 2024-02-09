#!/bin/bash

# Define the Linux Kernel OpenZFS version we want to build in
# this file, as well as our custom kernel name.

export KERNELVER="5.15.146.1"  # https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/linux-msft-wsl-5.15.146.1.tar.gz
export ZFSVER="2.2.2"  # https://zfsonlinux.org/
export KERNELNAME="kvm-zfs"
