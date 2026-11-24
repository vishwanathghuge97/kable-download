#!/usr/bin/env bash
# Kable one-command Linux installer.
#
# Downloads the latest kable-linux-x64.tar.gz and its SHA-256 file, verifies
# the checksum, then runs the per-user installer from the extracted bundle.
# Everything is installed under ~/.local; no root is needed or wanted.
#
# Usage:
#   curl -fsSL https://vishwanathghuge97.github.io/kable-download/install.sh | bash
set -euo pipefail
umask 077

BASE_URL="https://github.com/vishwanathghuge97/kable-download/releases/latest/download"
TARBALL="kable-linux-x64.tar.gz"
CHECKSUM="$TARBALL.sha256"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '==> %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] \
  || die "run this as your normal user, not root; Kable installs under your home directory"

for bin in curl tar sha256sum mktemp; do
  command -v "$bin" >/dev/null 2>&1 || die "'$bin' is required"
done

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kable-install.XXXXXX")"
trap 'rm -rf -- "$TMP_DIR"' EXIT

note "Downloading the latest Kable Linux bundle"
curl -fsSL --retry 3 --connect-timeout 15 -o "$TMP_DIR/$TARBALL" "$BASE_URL/$TARBALL"
curl -fsSL --retry 3 --connect-timeout 15 -o "$TMP_DIR/$CHECKSUM" "$BASE_URL/$CHECKSUM"

note "Verifying the SHA-256 checksum"
(
  cd "$TMP_DIR"
  sha256sum -c "$CHECKSUM"
)

note "Extracting"
tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"

note "Running the installer"
# Invoke bash explicitly: the temp directory is sometimes mounted noexec.
bash "$TMP_DIR/kable-linux-x64/install.sh"
