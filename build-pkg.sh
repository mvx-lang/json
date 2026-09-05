#!/bin/sh
# build-pkg.sh — stage the json BASIC codec into $1 for the uv and jbase
# artifacts.  Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
#   sh build-pkg.sh <stagedir>
#
# json's non-mvx side is PURE BASIC -- JSONDECODE and JSONENCODE, no CallC, no
# native build (src/mvxjson.c is the mvx extension and is built with mvx).  The
# same two functions serve udt, uv and jbase, so this stages the same tree for
# each and only the system name in the artifact key differs.
#
# Contents at the root, not wrapped in a json/ directory, to match what
# build-udt.sh has always staged -- so all three artifacts unpack the same way
# and MVPKG treats them alike.
#
# `any-any-le` on a hosted runner: there is nothing compiled here to lock to an
# os or arch.  (The udt artifact is still built through the udt-build action on
# the self-hosted runner, which it does not need either -- worth folding in
# later, but changing a published artifact's shape is a separate change.)
set -e
STAGE="${1:?usage: build-pkg.sh <stagedir>}"
SRC="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$STAGE/BP"
cp "$SRC/udt/JSONDECODE" "$STAGE/BP/JSONDECODE"
cp "$SRC/udt/JSONENCODE" "$STAGE/BP/JSONENCODE"
for f in mvpkg.json PKG LICENSE README.md; do
   if [ -f "$SRC/$f" ]; then cp "$SRC/$f" "$STAGE/"; fi
done
# EVERY STAGED SOURCE GETS A TRAILING NEWLINE.  UniVerse's compiler rejects a
# source whose last line is unterminated -- "End of File unexpected, Was
# expecting: ';', End of Line" -- and the repo's items do not all have one, so this
# is not cosmetic: without it the uv artifact cannot be compiled on the target at
# all, and the package installs as a directory of sources that never become
# programs.  Appending only when it is missing keeps re-staging idempotent.
for f in "$STAGE"/BP/*; do
   [ -f "$f" ] || continue
   [ -n "$(tail -c 1 "$f")" ] && printf '\n' >> "$f"
done

echo "build-pkg: staged the json BASIC codec"
