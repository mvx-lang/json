#!/bin/sh
# json — assert the in-tree manifests agree with each other and with the tag.
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
#   sh tests/manifest-version.sh <version>
#
# WHY A CHECK AND NOT A STAMP.  mv_package stamps the tag into its staged
# manifests (version.sh, mvpkg_stamp_manifests) and that is the better answer
# where one script does the staging.  json's artifacts are staged in THREE
# places -- build-pkg.sh here for uv and jbase, mv-package-registry's udt-build
# action, and mvx's publish-source -- and two of those are outside this repo.
# Every one of them copies the in-tree PKG and mvpkg.json, so checking those two
# files once, before anything is built, makes all four artifacts right.
#
# WHAT WENT WRONG WITHOUT IT.  mvpkg.json said 1.3.0 through the 1.4.0 and 1.4.1
# releases and PKG line 2 said "1.3", so every published artifact declared a
# version two releases behind the tag it shipped under.  Nothing resolves against
# it -- mvpkg reads name, description, deploy and dependencies from a manifest
# and takes versions from the registry and the store inventory -- which is
# exactly why it drifted that far unnoticed.  MVPKG info on a stored manifest
# still reports it.
set -eu
WANT="${1:?usage: manifest-version.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rc=0

# A rolling dev tag is not a version and is not expected to match.
case "$WANT" in
  dev|latest) printf 'manifest-version: %s is not a version tag - skipped\n' "$WANT"; exit 0 ;;
esac

if [ -f "$ROOT/mvpkg.json" ]; then
  got=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/mvpkg.json" | head -1)
  if [ "$got" = "$WANT" ]; then
    printf '  ok   mvpkg.json version is %s\n' "$WANT"
  else
    printf '  FAIL mvpkg.json says "%s", the tag is "%s"\n' "$got" "$WANT"; rc=1
  fi
fi

# PKG is a line-oriented manifest: 1 name, 2 version, 3 description, 4 systems.
if [ -f "$ROOT/PKG" ]; then
  got=$(sed -n '2p' "$ROOT/PKG" | tr -d ' \r')
  if [ "$got" = "$WANT" ]; then
    printf '  ok   PKG line 2 is %s\n' "$WANT"
  else
    printf '  FAIL PKG line 2 says "%s", the tag is "%s"\n' "$got" "$WANT"; rc=1
  fi
fi

# AND THE SYSTEMS LISTS MUST AGREE, for the same reason the versions must.
# #35 dropped the mvx arm -- mvx has JSONENCODE/JSONDECODE in its runtime, so a
# package could not displace them if it tried -- and updated mvpkg.json and the
# README, but PKG line 4 still said "mvx udt uv jbase".  Both files ship in
# every artifact, so the published package declared a system it had been
# deliberately removed from, while line 5 of the same file excluded mvx from
# its only dependency.  Nothing resolves against PKG's copy, which is exactly
# why it survived the release -- the same blind spot the version check above
# exists for.
sysline=$(sed -n '4p' "$ROOT/PKG" 2>/dev/null | tr -s ' \r' ' ' | sed 's/^ *//;s/ *$//')
sysjson=$(sed -n '/"systems"/,/]/p' "$ROOT/mvpkg.json" 2>/dev/null \
          | sed -n 's/.*"\([a-z0-9_]*\)".*/\1/p' | grep -v '^systems$' | tr '\n' ' ' \
          | sed 's/ *$//')
if [ -n "$sysline" ] || [ -n "$sysjson" ]; then
  if [ "$sysline" = "$sysjson" ]; then
    printf '  ok   both manifests declare the systems "%s"\n' "$sysline"
  else
    printf '  FAIL PKG line 4 says "%s", mvpkg.json says "%s"\n' \
           "$sysline" "$sysjson"; rc=1
  fi
fi

if [ "$rc" -ne 0 ]; then
  printf 'manifests: make the two manifests agree, and name %s, before tagging\n' \
         "$WANT" >&2
fi
exit "$rc"
