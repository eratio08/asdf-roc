#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/roc-lang/roc"
GH_NIGHTLY_REPO="https://github.com/roc-lang/nightlies"
TOOL_NAME="roc"
TOOL_TEST="roc -V"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	# Sorts version numbers semantically (e.g., 0.0.9 < 0.0.10 < 0.1.0)
	# Transforms versions for numeric sorting, then restores original format
	# Example: 1.2.3-alpha+build → sorts correctly by major.minor.patch
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_releases() {
	local repo="${1:-$GH_NIGHTLY_REPO}"
	local api_url
	api_url="${repo/https:\/\/github.com/https://api.github.com/repos}"
	api_url="${api_url}/releases"

	curl "${curl_opts[@]}" "${api_url}?per_page=100" |
		grep -oE '"tag_name": "[^"]+"' |
		cut -d'"' -f4 |
		sed 's/^v//'
}

list_all_versions() {
	{
		list_github_releases "$GH_NIGHTLY_REPO"
		list_github_releases "$GH_REPO"
	} | sort_versions | uniq
}

get_repo_for_version() {
	local version="$1"
	if list_github_releases "$GH_NIGHTLY_REPO" | grep -q "^${version}$"; then
		echo "$GH_NIGHTLY_REPO"
	elif list_github_releases "$GH_REPO" | grep -q "^${version}$"; then
		echo "$GH_REPO"
	else
		echo "$GH_REPO"
	fi
}

get_download_url_from_github() {
	local repo="$1"
	local version="$2"
	local os="$3"
	local arch="$4"

	local api_url
	api_url="${repo/https:\/\/github.com/https://api.github.com/repos}"
	api_url="${api_url}/releases/tags/${version}"

	local pattern="${os}_${arch}.*\.tar\.gz"
	curl "${curl_opts[@]}" "$api_url" |
		grep -oE '"browser_download_url": "[^"]+"' |
		grep -E "$pattern" |
		head -n 1 |
		cut -d'"' -f4
}

download_release() {
	local version filename url repo
	version="$1"
	filename="$2"

	repo=$(get_repo_for_version "$version")

	arch=$(uname -m)
	os=$(uname)
	case $os in
	Linux)
		os="linux"
		;;
	Darwin)
		os="macos"
		;;
	*)
		os="unknown"
		;;
	esac

	if [ "$os" = "macos" ] && [ "$arch" = "arm64" ]; then
		arch="apple_silicon"
	fi

	url=$(get_download_url_from_github "$repo" "$version" "$os" "$arch")

	if [ -z "$url" ]; then
		fail "Could not find release asset for $TOOL_NAME $version (${os}_${arch})"
	fi

	echo "* Downloading $TOOL_NAME release $version from $(basename "$repo")..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		# TODO: Assert roc executable exists.
		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
