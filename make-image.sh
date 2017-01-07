#!/bin/bash
set -e

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 image_name [boot.cmd]"
  echo >&2 ""
  echo >&2 "Examples:"
  echo >&2 "  $0 firmware.Cubietruck.img"
  echo >&2 "  $0 firmware.MX6_Cubox-i.img"
  echo >&2 ""
  echo >&2 "Optional: set TTY1CONSOLE=true env to configure console to tty1"
  exit 1
fi
IMAGE_NAME="$1"
BOOTCMD="$2"
TMPDIR="tmp"
mkdir -p "$TMPDIR/source"
load-debian-source() {
  if [[ ! -f "$TMPDIR/source/$1" ]]; then
    wget "-O$TMPDIR/source/$1" "https://d-i.debian.org/daily-images/armhf/daily/netboot/SD-card-images/$1"
  fi
}
load-debian-source "$IMAGE_NAME.gz"
load-debian-source partition.img.gz

# Unpack images
zcat "$TMPDIR/source/$IMAGE_NAME.gz" > "$TMPDIR/$IMAGE_NAME"
zcat "$TMPDIR/source/partition.img.gz" > "$TMPDIR/partition.img"

# Config
if [[ -z "$BOOTCMD" ]]; then
  if [[ "$TTY1CONSOLE" == "true" ]]; then
    CONSOLEBLOCK='setenv console tty1
setenv bootargs fb=false'
  else
    CONSOLEBLOCK=''
  fi

  BOOTCMD="$TMPDIR/boot.cmd"
  cat > "$BOOTCMD" <<-TEXT
# Bootscript using the new unified bootcmd handling
# introduced with u-boot v2014.10

if test -n "\${boot_targets}"; then
  echo "Mainline u-boot / new-style environment detected."
else
  echo "Non-mainline u-boot or old-style mainline u-boot detected."
  echo "This boot script uses the unified bootcmd handling of mainline"
  echo "u-boot >=v2014.10, which is not available on your system."
  echo "Please boot the installer manually."
  exit 0
fi

if test -z "\${fdtfile}"; then
  echo 'fdtfile environment variable not set. Aborting boot process.'
  exit 0
fi

if test ! -e \${devtype} \${devnum}:\${bootpart} dtbs/\${fdtfile}; then
  echo "This installer medium does not contain a suitable device-tree file for"
  echo "this system (\${fdtfile}). Aborting boot process."
  exit 0
fi

${CONSOLEBLOCK}

# Some i.MX6-based systems do not encode the baudrate in the console variable
if test "\${console}" = "ttymxc0" && test -n "\${baudrate}"; then
  setenv console "\${console},\${baudrate}"
fi

if test -n "\${console}"; then
  setenv bootargs "\${bootargs} console=\${console}"
fi

load \${devtype} \${devnum}:\${bootpart} \${kernel_addr_r} vmlinuz \
&& load \${devtype} \${devnum}:\${bootpart} \${fdt_addr_r} dtbs/\${fdtfile} \
&& load \${devtype} \${devnum}:\${bootpart} \${ramdisk_addr_r} initrd.gz \
&& echo "Booting the Debian installer..." \
&& bootz \${kernel_addr_r} \${ramdisk_addr_r}:\${filesize} \${fdt_addr_r}
TEXT
fi
echo "Calling mkimage on $BOOTCMD:"
mkimage -C none -A arm -T script -d "$BOOTCMD" "$TMPDIR/boot.scr"

# Add config and self
mkdir -p "$TMPDIR/mnt"
umount "$TMPDIR/mnt" || true
mount -o loop "$TMPDIR/partition.img" "$TMPDIR/mnt"
cp "$TMPDIR/boot.scr" "$TMPDIR/mnt/boot.scr"
cp "$0" "$TMPDIR/mnt/make-image.sh"
sync
umount "$TMPDIR/mnt"

# Build final image
cat "$TMPDIR/$IMAGE_NAME" "$TMPDIR/partition.img" > "$TMPDIR/full-image.img"
echo "Image generated at $TMPDIR/full-image.img"
