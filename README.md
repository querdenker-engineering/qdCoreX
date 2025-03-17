# qdcorex

qdcorex is a Buildroot-based embedded Linux project for qde hardware products.

This repository contains the Buildroot external tree and board support for the
qdGate platform based on the STM32MP1 and DHCOR SoM.

## Repository layout

- `buildroot/` — pinned Buildroot submodule
- `external/` — qdcorex Buildroot external tree
- `external/board/qdgate-dhcor-stm32mp1/` — qdGate board support
- `external/configs/` — Buildroot configurations for development and release builds

## Build

Initialize the Buildroot submodule after cloning:

```sh
git submodule update --init --recursive
```

Build the development configuration:

```sh
make -C buildroot \
  BR2_EXTERNAL=../external \
  qdcorex_qdgate-dhcor-stm32mp1_develop_defconfig

make -C buildroot
```

For a release build, use:

```sh
make -C buildroot \
  BR2_EXTERNAL=../external \
  qdcorex_qdgate-dhcor-stm32mp1_release_defconfig

make -C buildroot
```

The generated images and deployment artifacts are placed in:

```text
buildroot/output/images/
```

Board-specific configuration and build information is documented in
`external/board/qdgate-dhcor-stm32mp1/README.md`.
