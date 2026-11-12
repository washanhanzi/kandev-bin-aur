#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

if [[ -n "${AUR_SSH_PRIVATE_KEY:-}" ]]; then
  umask 077
  printf '%s\n' "$AUR_SSH_PRIVATE_KEY" > "$workdir/key"
  unset AUR_SSH_PRIVATE_KEY
  # https://aur.archlinux.org/ publishes the Ed25519 host key fingerprint.
  printf '%s\n' 'aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN' > "$workdir/known_hosts"
  export GIT_SSH_COMMAND="ssh -i '$workdir/key' -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile='$workdir/known_hosts' -o HostKeyAlgorithms=ssh-ed25519"
fi

aur_checkout="$workdir/aur"
git clone ssh://aur@aur.archlinux.org/kandev-bin.git "$aur_checkout"
cp PKGBUILD .SRCINFO "$aur_checkout/"
git -C "$aur_checkout" add PKGBUILD .SRCINFO
if git -C "$aur_checkout" diff --cached --quiet; then
  echo 'AUR is up to date.'
  exit 0
fi

version=$(awk '$1 == "pkgver" { print $3; exit }' .SRCINFO)
release=$(awk '$1 == "pkgrel" { print $3; exit }' .SRCINFO)
git -C "$aur_checkout" commit -m "chore(aur): publish kandev-bin ${version}-${release}"
git -C "$aur_checkout" push origin HEAD:refs/heads/master
