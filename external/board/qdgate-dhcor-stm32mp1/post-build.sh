#!/bin/bash

POST_BUILD_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fixup_extlinux_dtb_name()
{
	# BR2_LINUX_KERNEL_INTREE_DTS_NAME can contain multiple space-separated DTB
	# names; extlinux.conf expects a single FDT file, so we take the first.
	local DTB_NAME
	DTB_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' "${BR2_CONFIG}" | awk '{print $1}')"
	if [ -z "${DTB_NAME}" ]; then
		# Out-of-tree DTBs are installed without their source directory by
		# default. Prefer the DTS from this board's custom source directory;
		# this also avoids selecting a stale DTB from an incremental build.
		local CUSTOM_DTS
		CUSTOM_DTS="$(find "${POST_BUILD_SCRIPT_DIR}/linux/dts" -type f -name '*.dts' -printf '%f\n' | sort | head -n 1)"
		DTB_NAME="${CUSTOM_DTS%.dts}"
		if [ -z "${DTB_NAME}" ]; then
			DTB_NAME="$(find "${TARGET_DIR}/boot" -maxdepth 1 -type f -name '*.dtb' -printf '%f\n' | sort | head -n 1)"
			DTB_NAME="${DTB_NAME%.dtb}"
		fi
	fi
	if [ -z "${DTB_NAME}" ]; then
		echo "Can not determine the device tree name from ${BR2_CONFIG}"
		exit 1
	fi
	DTB_NAME="${DTB_NAME##*/}"

	local EXTLINUX_PATH="${TARGET_DIR}/boot/extlinux/extlinux.conf"
	if [ ! -e "${EXTLINUX_PATH}" ]; then
		echo "Can not find extlinux ${EXTLINUX_PATH}"
		exit 1
	fi

	# Escape replacement for sed: delimiter is '|', but we still need to escape
	# backslashes and '&' (which expands to the match).
	local DTB_NAME_ESCAPED
	DTB_NAME_ESCAPED="$(printf '%s' "${DTB_NAME}" | sed -e 's/[\\&]/\\&/g')"
	sed -i -e "s|%DTB_NAME%|${DTB_NAME_ESCAPED}|g" "${EXTLINUX_PATH}"
}

write_os_release()
{
	local product_name="qdCoreX"
	local product_id="qdcorex"
	local product_version="0.1.0"
	local buildroot_version="${BR2_VERSION_FULL:-unknown}"
	local os_release_path="${TARGET_DIR}/usr/lib/os-release"

	cat > "${os_release_path}" <<EOF
NAME="${product_name}"
ID=${product_id}
PRETTY_NAME="${product_name} ${product_version} (Buildroot ${buildroot_version})"
VERSION="${product_version}"
VERSION_ID="${product_version}"
BUILDROOT_VERSION="${buildroot_version}"
EOF

	ln -snf ../usr/lib/os-release "${TARGET_DIR}/etc/os-release"
}

fixup_extlinux_dtb_name $@
write_os_release $@
