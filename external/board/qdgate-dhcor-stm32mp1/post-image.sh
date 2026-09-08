#!/usr/bin/env bash

#
# atf_image extracts the ATF binary image from DTB_FILE_NAME that appears in
# BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES in ${BR_CONFIG},
# then prints the corresponding file name for the genimage
# configuration file
#
atf_image()
{
	local ATF_VARIABLES="$(sed -n 's/^BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES="\(.*\)"$/\1/p' ${BR2_CONFIG})"

	local DTB_NAME="$(sed -n 's/.*DTB_FILE_NAME=\([^ ]*\)/\1/p' <<< ${ATF_VARIABLES})"
	local STM_NAME="tf-a-$(cut -f1 -d'.' <<< ${DTB_NAME}).stm32"
	echo ${STM_NAME}
}

main()
{
	local ATFBIN="$(atf_image)"
	if [ ! -e ${BINARIES_DIR}/${ATFBIN} ]; then
		echo "Can not find ATF binary ${ATFBIN}"
		exit 1
	fi

	local GENIMAGE_CFG=${2}
	local GENIMAGE_CFG_TMP="$(mktemp --suffix .genimage.cfg)"
	local GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
	local SCRIPT_PATH=$(dirname "$0")
	local BOOTFS_SOURCE
	BOOTFS_SOURCE="$(mktemp -d "${BUILD_DIR}/bootfs.XXXXXX")"

	# genimage.sh uses BINARIES_DIR as inputpath and an empty rootpath, so any
	# file referenced by genimage.cfg must exist under BINARIES_DIR.
	mkdir -p "${BINARIES_DIR}/extlinux"
	if [ -e "${TARGET_DIR}/boot/extlinux/extlinux.conf" ]; then
		cp -f "${TARGET_DIR}/boot/extlinux/extlinux.conf" "${BINARIES_DIR}/extlinux/extlinux.conf"
	fi

	# Stage the files required by the boot filesystem. Keep them below /boot so
	# the existing extlinux.conf paths remain valid.
	if [ ! -e "${BINARIES_DIR}/zImage" ]; then
		echo "Can not find kernel image ${BINARIES_DIR}/zImage"
		rm -rf "${BOOTFS_SOURCE}"
		exit 1
	fi
	if [ ! -e "${BINARIES_DIR}/extlinux/extlinux.conf" ]; then
		echo "Can not find extlinux configuration ${BINARIES_DIR}/extlinux/extlinux.conf"
		rm -rf "${BOOTFS_SOURCE}"
		exit 1
	fi
	local LINUX_DTB_NAME
	LINUX_DTB_NAME="$(sed -n 's|^[[:space:]]*devicetree[[:space:]]*/boot/\(.*\.dtb\)$|\1|p' \
		"${BINARIES_DIR}/extlinux/extlinux.conf")"
	if [ -z "${LINUX_DTB_NAME}" ] || [ ! -e "${BINARIES_DIR}/${LINUX_DTB_NAME}" ]; then
		echo "Can not find Linux device tree referenced by extlinux"
		rm -rf "${BOOTFS_SOURCE}"
		exit 1
	fi

	install -D -m 0644 "${BINARIES_DIR}/zImage" "${BOOTFS_SOURCE}/boot/zImage"
	install -D -m 0644 "${BINARIES_DIR}/extlinux/extlinux.conf" \
		"${BOOTFS_SOURCE}/boot/extlinux/extlinux.conf"
	install -D -m 0644 "${BINARIES_DIR}/${LINUX_DTB_NAME}" \
		"${BOOTFS_SOURCE}/boot/${LINUX_DTB_NAME}"
	for DTBO in "${BINARIES_DIR}"/*.dtbo; do
		[ -e "${DTBO}" ] || continue
		install -D -m 0644 "${DTBO}" \
			"${BOOTFS_SOURCE}/boot/overlays/$(basename "${DTBO}")"
	done

	# Reservierte Metadaten: identische Initialinhalte, noch kein FWU-Protokoll.
	dd if=/dev/zero of="${BINARIES_DIR}/metadata.bin" bs=512 count=1024 status=none || exit 1

	sed -e "s/%ATFBIN%/${ATFBIN}/" \
		-e "s|%BOOTFS_SOURCE%|${BOOTFS_SOURCE}|" \
		-e "s|%EMMC_CFG%|${SCRIPT_PATH}/genimage-emmc.cfg|" \
		${SCRIPT_PATH}/${GENIMAGE_CFG} > ${GENIMAGE_CFG_TMP}

	local GENIMAGE_STATUS=0
	support/scripts/genimage.sh -c "${GENIMAGE_CFG_TMP}" || GENIMAGE_STATUS=$?

	rm -f ${GENIMAGE_CFG_TMP}
	rm -rf "${BOOTFS_SOURCE}"
	if [ "${GENIMAGE_STATUS}" -ne 0 ]; then
		return "${GENIMAGE_STATUS}"
	fi

	local EMMC_FLASH_LAYOUT_SOURCE="${SCRIPT_PATH}/deploy/flash_layout_emmc.tsv"

	if [ -e "${EMMC_FLASH_LAYOUT_SOURCE}" ]; then
		cp -f "${EMMC_FLASH_LAYOUT_SOURCE}" "${BINARIES_DIR}/flash_layout_emmc.tsv"
	fi

	if [ -e "${BINARIES_DIR}/sdcard.img" ]; then
		gzip -fk "${BINARIES_DIR}/sdcard.img"
		${HOST_DIR}/bin/bmaptool create -o "${BINARIES_DIR}/sdcard.img.bmap" "${BINARIES_DIR}/sdcard.img"
	else
		echo "sdcard.img not generated, skipping gzip/bmaptool"
	fi

	exit $?
}

main $@
