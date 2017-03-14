# Bootscript using the new unified bootcmd handling
# introduced with u-boot v2014.10

if test -n "${boot_targets}"; then
  echo "Mainline u-boot / new-style environment detected."
else
  echo "Non-mainline u-boot or old-style mainline u-boot detected."
  echo "This boot script uses the unified bootcmd handling of mainline"
  echo "u-boot >=v2014.10, which is not available on your system."
  echo "Please boot the installer manually."
  exit 0
fi

if test -z "${fdtfile}"; then
  echo 'fdtfile environment variable not set. Aborting boot process.'
  exit 0
fi

if test ! -e ${devtype} ${devnum}:${bootpart} dtbs/${fdtfile}; then
  echo "This installer medium does not contain a suitable device-tree file for"
  echo "this system (${fdtfile}). Aborting boot process."
  exit 0
fi

# Some i.MX6-based systems do not encode the baudrate in the console variable
if test "${console}" = "ttymxc0" && test -n "${baudrate}"; then
  setenv console "${console},${baudrate}"
fi

if test -n "${console}"; then
  setenv bootargs "${bootargs} console=${console}"
fi

dhcp

setenv pxefile_addr_r 0x10006000
setenv kernel_addr_r ${loadaddr}
setenv ramdisk_addr_r 0x12000000
setenv fdt_addr_r ${fdt_addr}

pxe get
pxe boot
