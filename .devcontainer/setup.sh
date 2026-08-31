#!/usr/bin/env bash
# Installs the repo tool and primes ccache. Runs once, at container creation.
set -euo pipefail

mkdir -p "$HOME/bin"
if [ ! -x "$HOME/bin/repo" ]; then
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
    chmod a+x "$HOME/bin/repo"
fi

ccache -M 20G >/dev/null 2>&1 || true

cat <<'BANNER'

LineageOS 17.1 (hinoki) build container ready.

Disk is the constraint here, so sync shallow:

  mkdir -p ~/android && cd ~/android
  repo init -u https://github.com/LineageOS/android.git -b lineage-17.1 --depth=1
  mkdir -p .repo/local_manifests
  curl -L https://raw.githubusercontent.com/Ellosan/android_hinoki_manifest/main/local_manifest.xml \
      -o .repo/local_manifests/hinoki.xml
  repo sync -c --depth=1 --no-tags --no-clone-bundle -j"$(nproc --all)"

  source build/envsetup.sh && lunch lineage_hinoki-userdebug
  mka recoveryimage      # fits comfortably
  # mka bacon            # will very likely run out of disk here

BANNER
