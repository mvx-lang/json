#!/bin/sh
# json — stage the UniData (BASIC) codec into $1 for the udt-build action.
# json's udt side is pure BASIC (JSONDECODE/JSONENCODE) — no native build — so
# this just lays the functions into BP/ (where MVPKG's CATALOG op finds them)
# alongside the manifest.  (mvx is not a target: its runtime provides
# JSONENCODE/JSONDECODE built in, mvx#169.)
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only.
set -e
STAGE="${1:?usage: build-udt.sh <stagedir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$STAGE/BP"
cp "$SRC/BP/JSONDECODE" "$STAGE/BP/JSONDECODE"
cp "$SRC/BP/JSONENCODE" "$STAGE/BP/JSONENCODE"
cp "$SRC/mvpkg.json" "$SRC/PKG" "$SRC/LICENSE" "$STAGE/" 2>/dev/null || true
echo "build-udt: staged the json BASIC codec"
