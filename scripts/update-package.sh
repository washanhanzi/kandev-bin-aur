#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

repo=kdlbs/kandev
headers=(-H 'Accept: application/vnd.github+json')
if [[ -n "${GH_TOKEN:-}" ]]; then
  headers+=(-H "Authorization: Bearer ${GH_TOKEN}")
fi
release=$(curl --fail --silent --show-error --retry 3 "${headers[@]}" \
  "https://api.github.com/repos/${repo}/releases/latest")
tag=$(jq -er '.tag_name | select(test("^v(0|[1-9][0-9]*)(\\.(0|[1-9][0-9]*)){2}$"))' <<< "$release")
version=${tag#v}
current=$(sed -n 's/^pkgver=//p' PKGBUILD)
if [[ "$version" == "$current" ]] || [[ $(printf '%s\n' "$current" "$version" | sort -V | tail -n 1) != "$version" ]]; then
  printf 'Package is current at %s (latest stable release: %s).\n' "$current" "$version"
  exit 0
fi

asset_digest() {
  local asset="kandev-linux-$1-full.tar.gz"
  jq -er --arg asset "$asset" --arg url "https://github.com/${repo}/releases/download/${tag}/${asset}" '
    [.assets[] | select(.name == $asset and .browser_download_url == $url and .state == "uploaded")]
    | if length == 1 then .[0].digest else empty end
    | strings | select(test("^sha256:[a-f0-9]{64}$")) | sub("^sha256:"; "")
  ' <<< "$release"
}

x86_64_digest=$(asset_digest x64) || { echo "Missing x86_64 asset or SHA-256 digest for $tag" >&2; exit 1; }
aarch64_digest=$(asset_digest arm64) || { echo "Missing aarch64 asset or SHA-256 digest for $tag" >&2; exit 1; }

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
sed -e "s/^pkgver=.*/pkgver=${version}/" \
    -e 's/^pkgrel=.*/pkgrel=1/' \
    -e "s/^sha256sums_x86_64=.*/sha256sums_x86_64=('${x86_64_digest}')/" \
    -e "s/^sha256sums_aarch64=.*/sha256sums_aarch64=('${aarch64_digest}')/" \
    PKGBUILD > "$workdir/PKGBUILD"

if command -v makepkg >/dev/null; then
  (cd "$workdir" && makepkg --printsrcinfo) > "$workdir/.SRCINFO"
else
  docker run --rm --user "$(id -u):$(id -g)" \
    --volume "$workdir:/pkg:ro" --workdir /pkg archlinux:base \
    makepkg --printsrcinfo > "$workdir/.SRCINFO"
fi
cp "$workdir/PKGBUILD" "$workdir/.SRCINFO" .
printf 'Updated kandev-bin from %s to %s.\n' "$current" "$version"
