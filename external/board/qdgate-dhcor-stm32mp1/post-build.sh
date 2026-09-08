#!/bin/bash

POST_BUILD_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${POST_BUILD_SCRIPT_DIR}/../../scripts/qdcorex-version.sh"
QDCOREX_ROOT="$(cd -- "${POST_BUILD_SCRIPT_DIR}/../.." && pwd)"

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

read_config_value()
{
	local config_symbol="$1"

	[ -r "${BR2_CONFIG:-}" ] || return 0
	sed -n "s/^${config_symbol}=\"\(.*\)\"$/\1/p" "${BR2_CONFIG}" | head -n 1
}

OS_NAME="${BR2_OS_NAME:-qdCoreX}"
OS_ID="${BR2_OS_ID:-qdcorex}"
OS_VERSION="${BR2_OS_VERSION:-unknown}"
QDCOREX_VERSION="$(qdcorex_version_from_source "${QDCOREX_ROOT}")"

config_value="$(read_config_value BR2_OS_NAME)"
[ -z "${config_value}" ] || OS_NAME="${config_value}"
config_value="$(read_config_value BR2_OS_ID)"
[ -z "${config_value}" ] || OS_ID="${config_value}"
config_value="$(read_config_value BR2_OS_VERSION)"
[ -z "${config_value}" ] || OS_VERSION="${config_value}"
config_value="$(read_config_value BR2_QDCOREX_VERSION)"
[ -z "${config_value}" ] || QDCOREX_VERSION="${config_value}"

for arg in "$@"; do
	case "${arg}" in
		OS_NAME=*)
			OS_NAME="${arg#OS_NAME=}"
			;;
		OS_ID=*)
			OS_ID="${arg#OS_ID=}"
			;;
		OS_VERSION=*)
			OS_VERSION="${arg#OS_VERSION=}"
			;;
		QDCOREX_VERSION=*)
			QDCOREX_VERSION="${arg#QDCOREX_VERSION=}"
			;;
	esac
done

write_os_release()
{
	local buildroot_version="${BR2_VERSION_FULL:-unknown}"
	local os_release_path="${TARGET_DIR}/usr/lib/os-release"

	cat > "${os_release_path}" <<EOF
NAME="${OS_NAME}"
ID=${OS_ID}
PRETTY_NAME="${OS_NAME} ${OS_VERSION}"
VERSION="${OS_VERSION}"
VERSION_ID="${OS_VERSION}"
QDCOREX_VERSION="${QDCOREX_VERSION}"
BUILDROOT_VERSION="${buildroot_version}"
EOF

	if [ "${OS_ID}" != "qdcorex" ]; then
		echo 'ID_LIKE=qdcorex' >> "${os_release_path}"
	fi

	ln -snf ../usr/lib/os-release "${TARGET_DIR}/etc/os-release"
}

fixup_extlinux_dtb_name "$@"
write_os_release "$@"
