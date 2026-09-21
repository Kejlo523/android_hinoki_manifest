#!/system/bin/sh
# Lineage Recovery entry point. The upstream APK stays byte-for-byte intact.
set -eu
export PATH=/system/bin:/sbin:$PATH
api=$1
output_fd=$2
archive=$3
ui_print() {
    printf 'ui_print %s\nui_print\n' "$*" > "/proc/self/fd/$output_fd"
}
abort() { ui_print "$*"; exit 1; }
case "$(getprop ro.product.device)" in
    hinoki|xperia_xa1|XPERIA_XA1) ;;
    *) abort 'This installer is for Xperia XA1 / hinoki only.' ;;
esac
stage=$(mktemp -d /tmp/hinoki-magisk.XXXXXX)
trap 'rm -rf "$stage"' EXIT
unzip -p "$archive" payload/Magisk.apk > "$stage/Magisk.apk"
test -s "$stage/Magisk.apk" || abort 'Missing upstream Magisk APK.'
mkdir "$stage/check"
unzip -p "$stage/Magisk.apk" lib/arm64-v8a/libmagiskboot.so > "$stage/check/magiskboot"
chmod 0755 "$stage/check/magiskboot"
boot=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name/boot
test -b "$boot" || abort 'Cannot find the boot partition.'
dd if="$boot" of="$stage/check/boot.img" bs=1048576 2>/dev/null
cd "$stage/check"
./magiskboot unpack -h boot.img >&2 || abort 'Cannot unpack boot image.'
test -s ramdisk.cpio || abort 'Install the hinoki first-stage ramdisk ROM before Magisk.'
./magiskboot cpio ramdisk.cpio 'exists init' || abort 'Boot ramdisk has no init.'
if grep -q 'skip_initramfs' header; then
    abort 'Legacy SAR boot detected. Install the first-stage ramdisk ROM first.'
fi
cd /
ui_print 'Installing official Magisk into the hinoki boot ramdisk.'
# Keep filesystem verification/encryption settings unchanged by the patcher.
export KEEPVERITY=true KEEPFORCEENCRYPT=true RECOVERYMODE=false LEGACYSAR=false
unzip -p "$stage/Magisk.apk" META-INF/com/google/android/update-binary > "$stage/upstream-installer.sh"
# Explicit interpreter also works on Lineage Recovery, which has no /sbin/sh.
/system/bin/sh "$stage/upstream-installer.sh" "$api" "$output_fd" "$stage/Magisk.apk"
