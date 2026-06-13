#!/bin/bash
set -e

# Note: Do not depend on distro specific things like apt, if there is something
# distro specific, recreate it.

rm -rf ./initramfsworkdir
mkdir -p ./initramfsworkdir
cd ./initramfsworkdir

# APT recreations

# Downloads Packages.gz for a given distro/component/arch
apt_update() {
    local DIST="${1:-bookworm}"
    local COMPONENT="${2:-main}"
    local ARCH="${3:-binary-amd64}"
    local BASE="${4:-https://deb.debian.org/debian}"

    local URL="$BASE/dists/$DIST/$COMPONENT/$ARCH/Packages.gz"

    echo "[*] Downloading package index:"
    echo "    $URL"

    mkdir -p "./apt-cache"

    curl -L "$URL" -o "./apt-cache/Packages.gz"

    gunzip -f "./apt-cache/Packages.gz"

    echo "[✓] Saved to ./apt-cache/Packages"
}

# Cleans up APT stuff
apt_clean() {
    rm -r ./apt-cache
}

# Finds a package and installs/extracts it into a folder
apt_install() {
    local PKG="$1"
    local DEST=$(realpath "${2:-./rootfs}")
    local BASE="${3:-https://deb.debian.org/debian}"

    local PKGFILE="./apt-cache/Packages"

    if [ ! -f "$PKGFILE" ]; then
        echo "[-] Run apt_update first"
        return 1
    fi

    echo "[*] Searching for package: $PKG"

    local DEB_PATH
    DEB_PATH=$(awk -v pkg="$PKG" '
        $0 == "Package: " pkg {found=1}
        found && $0 ~ /^Filename:/ {print $2; exit}
    ' "$PKGFILE")

    if [ -z "$DEB_PATH" ]; then
        echo "[-] Package not found"
        return 1
    fi

    local URL="$BASE/$DEB_PATH"

    echo "[+] Found: $URL"

    mkdir -p "$DEST/tmp"

    local TMP_DEB="$DEST/tmp/package.deb"

    echo "[*] Downloading..."
    curl -L "$URL" -o "$TMP_DEB"

    echo "[*] Extracting into $DEST"

    mkdir -p "$DEST"

    # Extract .deb
    cd ./tmp
    ar x "$DEST/tmp/package.deb"
    tar -xf data.tar.* -C "$DEST"
    cd -

    echo "[✓] Installed into $DEST"
}

debian_arch() {
    case "$(uname -m)" in
        x86_64)
            echo "amd64"
            ;;
        i386|i686)
            echo "i386"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "armhf"
            ;;
        armv6l)
            echo "armel"
            ;;
        riscv64)
            echo "riscv64"
            ;;
        ppc64le)
            echo "ppc64el"
            ;;
        s390x)
            echo "s390x"
            ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

trap apt_clean EXIT

# Set up APT
apt_update bookworm main binary-$(debian_arch)

# Install busybox
apt_install busybox-static .

# Use the installed busybox to create symlinks for all the applets
cd ./bin
./busybox --install .
cd -

# Install the initramfs folder
cp -r ../initramfs/* ./

# Create initramfs.cpio.gz
find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz

# Delete the workdir
cd ..
rm -rf ./initramfsworkdir
trap - EXIT