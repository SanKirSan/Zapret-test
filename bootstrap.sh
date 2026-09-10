#!/bin/sh
set -eu

# zapret-test GitHub bootstrap installer.
# Replace these defaults before publishing the repository. They may also be overridden
# with ZAPRET_TEST_REPO and ZAPRET_TEST_REF environment variables.
REPO="${ZAPRET_TEST_REPO:-SanKirSan/Zapret-test}"
REF="${ZAPRET_TEST_REF:-main}"
BASE="https://raw.githubusercontent.com/$REPO/$REF"
ARCHIVE_URL="${ZAPRET_TEST_ARCHIVE_URL:-https://github.com/$REPO/archive/refs/heads/$REF.tar.gz}"

TMP_ROOT="${TMPDIR:-/tmp}/zapret-test-bootstrap.$$"
cleanup(){ rm -rf "$TMP_ROOT"; }
trap cleanup EXIT INT TERM
mkdir -p "$TMP_ROOT"

printf '%s\n' "Downloading zapret-test from $REPO ($REF)..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 2 --connect-timeout 8 --max-time 60 "$BASE/install.sh" -o "$TMP_ROOT/install.sh" || exit 1
    curl -fsSL --retry 2 --connect-timeout 8 --max-time 60 "$BASE/build.sh" -o "$TMP_ROOT/build.sh" || true
else
    command -v wget >/dev/null 2>&1 || { echo 'ERROR: curl or wget is required.' >&2; exit 2; }
    wget -q -O "$TMP_ROOT/install.sh" "$BASE/install.sh" || exit 1
    wget -q -O "$TMP_ROOT/build.sh" "$BASE/build.sh" || true
fi

# The normal installer expects the full source tree.
# GitHub provides a tar.gz source archive that works with BusyBox tar on OpenWrt.
if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 2 --connect-timeout 8 --max-time 120 "$ARCHIVE_URL" -o "$TMP_ROOT/repo.tar.gz" || exit 1
else
    wget -q -T 20 -O "$TMP_ROOT/repo.tar.gz" "$ARCHIVE_URL" || exit 1
fi

command -v tar >/dev/null 2>&1 || { echo 'ERROR: tar is required for bootstrap installation.' >&2; exit 3; }
mkdir -p "$TMP_ROOT/src"
tar -xzf "$TMP_ROOT/repo.tar.gz" -C "$TMP_ROOT/src"
SRC_DIR=$(find "$TMP_ROOT/src" -mindepth 1 -maxdepth 1 -type d -print | head -n1)
[ -n "$SRC_DIR" ] || { echo 'ERROR: source archive has no source directory.' >&2; exit 4; }
chmod +x "$SRC_DIR/install.sh"
exec "$SRC_DIR/install.sh"
