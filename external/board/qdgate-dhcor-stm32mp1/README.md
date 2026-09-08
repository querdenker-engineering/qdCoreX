# qdGate with DHCOR STM32MP13

## Build and flash artifacts

From the repository root:

```sh
make -C buildroot BR2_EXTERNAL=../external qdcorex_qdgate-dhcor-stm32mp1_develop_defconfig
make -C buildroot
```
