# LineageOS 17.1 for Sony Xperia XA1 Dual (G3112)

Complete source manifest for the unofficial Android 10 port for Sony Xperia
XA1 Dual (`hinoki`, G3112).

## Build

Start with a normal LineageOS 17.1 build environment:

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1
mkdir -p .repo/local_manifests
curl -L https://raw.githubusercontent.com/Kejlo523/android_hinoki_manifest/main/local_manifest.xml \
    -o .repo/local_manifests/hinoki.xml
repo sync -c -j$(nproc --all)

source build/envsetup.sh
lunch lineage_hinoki-userdebug
mka bacon
```

The flashable ZIP is written to `out/target/product/hinoki/`.

Use `local_manifest-pinned.xml` instead of `local_manifest.xml` when you need
the exact revisions used for the 2026-09-17 V23 build.

## Device baseline

- Device: Xperia XA1 Dual G3112
- Required stock firmware baseline: `48.1.A.2.112`
- Android: 10 / LineageOS 17.1
- Kernel: [android_kernel_sony_mt6757](https://github.com/Kejlo523/android_kernel_sony_mt6757/tree/lineage-17.1-hinoki)
- Build-specific kernel commit: [`7d74b285`](https://github.com/Kejlo523/android_kernel_sony_mt6757/commit/7d74b28506bdaf4c025b602b6a50ad58f017ed5a)
- Google apps are not included.

## Current compatibility notes

This is still an unofficial alpha port built around Sony/MediaTek Oreo vendor
components. The tree contains the compatibility work for camera, audio, RIL,
storage, Wi-Fi, HWC and media used by the current ROM.

- Hardware MTK video decoders are disabled because their Oreo Vcodec ABI
  crashes Android 10 media services. Android software decoders are used.
- Screen recording uses the Android software AVC encoder.
- MTP uses the legacy MediaTek gadget path with synchronized teardown and has
  been verified with repeated checksum-matched transfers.
- NFC is deliberately limited to stable NFC-A polling. Android Beam/P2P and
  the parallel NXP extension HAL are disabled to avoid controller hangs.
- The device currently uses the primary SIM path; dual-SIM behavior remains
  incomplete.
- SELinux is enforcing with the legacy MediaTek vendor domains restored.
- Device Info HW, Kernel Adiutor, DuckDuckGo and an app-scoped `su`/BusyBox
  environment are included as system components.

Contributions and device logs attached to reproducible bug reports are
welcome.

## Credits

Based on the original SonyMTKDev hinoki, MT6757 common, vendor and kernel trees,
with LineageOS as the Android base.
