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
	CUSTOMER="customer" #TODO: replace customer
	PROJECT="projeCt"	#TODO: replace project

	local ATFBIN="$(atf_image)"
	if [ ! -e ${BINARIES_DIR}/${ATFBIN} ]; then
		echo "Can not find ATF binary ${ATFBIN}"
		exit 1
	fi
	local GENIMAGE_CFG=${2}
	local GENIMAGE_CFG_TMP="$(mktemp --suffix .genimage.cfg)"
	local GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
	local SCRIPT_PATH=$(dirname "$0")

	sed -e "s/%ATFBIN%/${ATFBIN}/" \
		${SCRIPT_PATH}/${GENIMAGE_CFG} > ${GENIMAGE_CFG_TMP}

	support/scripts/genimage.sh -c ${GENIMAGE_CFG_TMP}

	rm -f ${GENIMAGE_CFG_TMP}

	gzip -fk ${BINARIES_DIR}/sdcard.img
	${HOST_DIR}/bin/bmaptool create -o ${BINARIES_DIR}/sdcard.img.bmap ${BINARIES_DIR}/sdcard.img

	#generate rauc bundle
	mkdir -p ${BINARIES_DIR}/rauc
	sed -e "s/^version=/version=${FIRMWARE_VERSION}/g" \
		-e "s/%ROOTFS_SUFFIX%/${ROOTFS_SUFFIX}/" \
		-e "s/%COMPATIBLE%/${COMPATIBLE}/" \
		$(dirname $0)/rauc/manifest.raucm > ${BINARIES_DIR}/rauc/manifest.raucm
	cp ${BINARIES_DIR}/boot.vfat ${BINARIES_DIR}/rauc/boot.vfat
	cp ${BINARIES_DIR}/rootfs.${ROOTFS_SUFFIX} ${BINARIES_DIR}/rauc/rootfs.${ROOTFS_SUFFIX}
	zip -j ${BINARIES_DIR}/rauc_data.zip ${BINARIES_DIR}/rauc/* $(dirname $0)/rauc/cert.pem
	curl -F "file=@${BINARIES_DIR}/rauc_data.zip" -F "project=${CUSTOMER}/${PROJECT}/rauc" -H "x-api-key: ${RAUC_SIGN_AUTH}" --output ${BINARIES_DIR}/firmware $KEY_SERVER_ADDRESS
	rm -rf ${BINARIES_DIR}/rauc ${BINARIES_DIR}/rauc_data.zip

	exit $?
}

main $@
