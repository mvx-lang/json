#!/bin/sh
# json — stage the UniData (BASIC) codec into $1 for the udt-build action.
# json's udt side is pure BASIC (JSONDECODE/JSONENCODE) — no native build — so
# this just lays the functions into BP/ (where MVPKG's CATALOG op finds them)
# alongside the manifest.  The mvx side is the native src/ (built with mvx).
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only.
set -e
STAGE="${1:?usage: build-udt.sh <stagedir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$STAGE/BP"
cp "$SRC/udt/JSONDECODE" "$STAGE/BP/JSONDECODE"
cp "$SRC/udt/JSONENCODE" "$STAGE/BP/JSONENCODE"
cp "$SRC/mvpkg.json" "$SRC/PKG" "$SRC/LICENSE" "$STAGE/" 2>/dev/null || true
echo "build-udt: staged the json BASIC codec"
