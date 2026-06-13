#!/usr/bin/env bash
set -e

# Note: Do not depend on distro specific things like apt, if there is something
# distro specific, recreate it.

rm -rf ./rootfsworkdir
mkdir -p ./rootfsworkdir
cd ./rootfsworkdir

# Load libraries
source ../lib/apt.sh

# Set up APT
apt_update bookworm main binary-$(debian_arch)

# Install packages
apt_install busybox .
apt_install libc6 .
apt_install libgcc-s1 .
apt_install gcc-12-base .

# Use the installed busybox to create symlinks for all the applets
cd ./bin
./busybox --install .
cd -

# Remove APT cache
apt_clean

# Install the rootfs folder
cp -r ../rootfs/* ./

# Create rootfs.qcow2
cd ..
qemu-img create -f qcow2 rootfs.qcow2 2G
echo "If formatting fails, run the script with export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1"
guestfish -a rootfs.qcow2 -f make_rootfs.gf

# Delete the workdir
rm -rf ./rootfsworkdir
trap - EXIT