#!/usr/bin/env bash
set -e

# Note: Do not depend on distro specific things like apt, if there is something
# distro specific, recreate it.

rm -rf ./initramfsworkdir
mkdir -p ./initramfsworkdir
cd ./initramfsworkdir

# Load libraries
source ../lib/apt.sh

# Set up APT
apt_update bookworm main binary-$(debian_arch)

# Install busybox
apt_install busybox-static .

# Use the installed busybox to create symlinks for all the applets
cd ./bin
./busybox --install .
cd -

# Remove APT cache
apt_clean

# Install the initramfs folder
cp -r ../initramfs/* ./

# Create initramfs.cpio.gz
find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz

# Delete the workdir
cd ..
rm -rf ./initramfsworkdir
trap - EXIT