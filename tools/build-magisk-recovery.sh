#!/usr/bin/env bash
# Wrap an official APK for sideload in Lineage Recovery with our OTA certificate.
set -euo pipefail
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 SOURCE_ROOT MAGISK_APK KEY_DIRECTORY OUTPUT_ZIP" >&2
    exit 2
fi
source_root=$(realpath "$1")
magisk_apk=$(realpath "$2")
key_dir=$(realpath "$3")
output_zip=$(realpath -m "$4")
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test ! -e "$output_zip" || { echo "Refusing to overwrite $output_zip" >&2; exit 1; }
unzip -tq "$magisk_apk"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/META-INF/com/google/android" "$stage/payload" "$(dirname "$output_zip")"
cp "$magisk_apk" "$stage/payload/Magisk.apk"
cp "$script_dir/magisk-recovery-update-binary.sh" "$stage/META-INF/com/google/android/update-binary"
chmod 0755 "$stage/META-INF/com/google/android/update-binary"
(cd "$stage" && zip -q -r unsigned.zip META-INF payload)
"$source_root/prebuilts/jdk/jdk9/linux-x86/bin/java" \
    -Djava.library.path="$source_root/out/host/linux-x86/lib64" \
    -jar "$source_root/out/host/linux-x86/framework/signapk.jar" -w \
    "$key_dir/releasekey.x509.pem" "$key_dir/releasekey.pk8" \
    "$stage/unsigned.zip" "$output_zip"
unzip -tq "$output_zip"
sha256sum "$output_zip" > "${output_zip%.zip}.sha256"
echo "Signed recovery installer: $output_zip"
