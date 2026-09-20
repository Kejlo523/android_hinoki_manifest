#!/usr/bin/env bash
# Sign an existing hinoki target-files build and preserve installed addon.d apps.
set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 SOURCE_ROOT TARGET_FILES_ZIP KEY_DIRECTORY OUTPUT_ZIP" >&2
    exit 2
fi

source_root=$(realpath "$1")
target_files=$(realpath "$2")
key_dir=$(realpath "$3")
output_zip=$(realpath -m "$4")
release_name=$(basename "${output_zip%.zip}")
signed_target_files="$(dirname "$target_files")/${release_name}-target_files.zip"
recovery_image="${output_zip%.zip}-recovery.img"

for artifact in "$output_zip" "$signed_target_files" "$recovery_image"; do
    if [ -e "$artifact" ]; then
        echo "Refusing to overwrite existing release artifact: $artifact" >&2
        exit 1
    fi
done
for key in releasekey platform media shared networkstack; do
    test -r "$key_dir/$key.pk8"
    test -r "$key_dir/$key.x509.pem"
done

cd "$source_root"
export PATH="$source_root/prebuilts/jdk/jdk9/linux-x86/bin:$PATH"
mkdir -p "$(dirname "$output_zip")"

python3 build/tools/releasetools/sign_target_files_apks \
    -p out/host/linux-x86 -o -d "$key_dir" \
    -k "build/make/target/product/security/networkstack=$key_dir/networkstack" \
    "$target_files" "$signed_target_files"

# The standalone releasetool defaults to backup=false, even though `mka bacon`
# enables it.  Omitting this option erases installed GApps at every signed OTA.
python3 build/tools/releasetools/ota_from_target_files \
    -p out/host/linux-x86 --block --backup=true \
    -k "$key_dir/releasekey" "$signed_target_files" "$output_zip"

python3 - "$output_zip" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    script = archive.read("META-INF/com/google/android/updater-script").decode()
    backup = script.index('backuptool.sh", "backup"')
    update = script.index("block_image_update(")
    restore = script.index('backuptool.sh", "restore"')
    if not backup < update < restore:
        raise SystemExit("Invalid addon.d backup/update/restore ordering")
    for name in ("install/bin/backuptool.sh", "install/bin/backuptool.functions"):
        if not archive.read(name):
            raise SystemExit("Missing addon.d helper: " + name)
    bad = archive.testzip()
    if bad:
        raise SystemExit("Corrupt ZIP member: " + bad)
print("Verified addon.d backup/restore ordering and ZIP integrity")
PY

unzip -p "$signed_target_files" IMAGES/recovery.img > "$recovery_image"
sha256sum "$output_zip" "$recovery_image" > "${output_zip%.zip}.sha256"
printf 'Signed OTA: %s\nRecovery: %s\n' "$output_zip" "$recovery_image"
