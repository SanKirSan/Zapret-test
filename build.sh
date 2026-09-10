#!/bin/sh
set -eu
NAME="zapret-test"
ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
VERSION=$(cat "$ROOT/VERSION")
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-0}
DIST="$ROOT/${NAME}-${VERSION}.zip"

test "$(cat "$ROOT/RELEASE")" = "$VERSION"
grep -q "^VERSION=\"$VERSION\"" "$ROOT/zapret-test"
sh -n "$ROOT/zapret-test"
sh -n "$ROOT/install.sh"
sh -n "$ROOT/build.sh"
rm -rf "$ROOT/build" "$DIST"
mkdir -p "$ROOT/build/$NAME"
(cd "$ROOT" && tar \
  --sort=name \
  --mtime="@$SOURCE_DATE_EPOCH" \
  --owner=0 --group=0 --numeric-owner \
  --exclude='./build' \
  --exclude='./*.zip' \
  --exclude='./.git' \
  --exclude='./zapret-test.prepatch' \
  --exclude='./*.before-*' \
  -cf - .) | tar -C "$ROOT/build/$NAME" -xf -
(cd "$ROOT/build" && zip -qrX "$DIST" "$NAME")
rm -rf "$ROOT/build"
sha256sum "$DIST" 2>/dev/null || shasum -a 256 "$DIST"
