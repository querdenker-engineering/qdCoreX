qdcorex_version_from_source()
{
	local qdcorex_root="$1"
	local version_file="${qdcorex_root}/VERSION"
	local base_version="unknown"
	local head
	local short_hash
	local version_tag
	local version_tag_candidate
	local commit_count

	if [ -r "${version_file}" ]; then
		base_version="$(sed -n '1{s/[[:space:]]*$//;p;}' "${version_file}")"
	fi
	[ -n "${base_version}" ] || base_version="unknown"

	# The VERSION file remains authoritative. Git is used only to append
	# source-state information and never to replace the base version with a
	# customer repository's unrelated tag.
	if ! git -C "${qdcorex_root}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		printf '%s\n' "${base_version}"
		return 0
	fi

	head="$(git -C "${qdcorex_root}" rev-parse --verify HEAD 2>/dev/null)" || {
		printf '%s\n' "${base_version}"
		return 0
	}
	short_hash="$(git -C "${qdcorex_root}" rev-parse --short=12 HEAD 2>/dev/null)"
	version="${base_version}"

	# Only recognize a tag that matches the central base version. This avoids
	# adopting arbitrary tags from a customer's fork as the qdCoreX version.
	for version_tag_candidate in "v${base_version}" "${base_version}"; do
		if git -C "${qdcorex_root}" rev-parse --verify --quiet \
			"${version_tag_candidate}^{commit}" >/dev/null 2>&1 \
			&& git -C "${qdcorex_root}" merge-base --is-ancestor \
			"${version_tag_candidate}^{commit}" "${head}" >/dev/null 2>&1; then
			version_tag="${version_tag_candidate}"
			break
		fi
	done

	if [ -n "${version_tag}" ]; then
		commit_count="$(git -C "${qdcorex_root}" rev-list --count \
			"${version_tag}..${head}" 2>/dev/null)"
		if [ "${commit_count}" -gt 0 ] 2>/dev/null; then
			version="${base_version}-${commit_count}-g${short_hash}"
		fi
	else
		# A Git repository without the matching release tag still gets a
		# traceable source suffix, while the VERSION file remains the base.
		version="${base_version}+g${short_hash}"
	fi

	# Do not use 'git describe --dirty': it may try to create .git/index.lock.
	# This read-only status check also works with read-only source trees.
	if git --no-optional-locks -C "${qdcorex_root}" status \
		--porcelain --untracked-files=no 2>/dev/null | grep -q .; then
		version="${version}-dirty"
	fi

	printf '%s\n' "${version}"
}
