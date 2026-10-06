#!/bin/sh
# json — what CI runs inside the licensed jBASE container (mvx-lang/json#40).
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
# Kept out of the workflow so the quoting stays sane, and so it can be run by
# hand -- which is how it was developed:
#
#   jbase-run 'sh /pkg/.github/jbase-ci.sh'
#
# tests/JSON.ESCAPES is the real test of this package: it round-trips the codec
# and prints FAILURES=0.  It needs a real ACCOUNT, because the three functions
# have to be compiled and CATALOGed before a program can DEFFUN them, and that
# is why it was run by hand for as long as it was.
set -eu

SRC="${JSON_SRC:-/pkg}"
MAPFIELD="${MAPFIELD_SRC:-$SRC/.deps/mapfield}"
ACCT="${JSON_ACCT:-/tmp/jsonci}"
LOG="${JSON_LOG:-/tmp/jsonci.log}"

# JSON.ESCAPES CALLS MAPFIELD() to build its spec, so mapfield is not optional
# here; say which path was looked at rather than failing later as a compile
# error in a program nobody changed.
[ -f "$MAPFIELD/BP/MAPFIELD" ] || {
    echo "::error::no mapfield at $MAPFIELD -- JSON.ESCAPES calls MAPFIELD()" >&2
    exit 1
}

# CREATE-ACCOUNT, NOT mkdir.  A jBASE account has an MD (whose dictionary is
# MD]D), a bin and a lib; a bare directory has none of them, so CATALOG has
# nowhere to put an object -- and the run goes green about something no user
# would ever have.  mv_git had 48 assertions passing that way (mv_git#114).
#
# THE NAME IS REGISTERED, NOT THE PATH.  CREATE-ACCOUNT records the basename in
# jBASE's SYSTEM file and REFUSES one already there, and removing the directory
# does not remove the registration.  CI gets a fresh container every run so this
# only bites when running it by hand -- which is exactly when a silent refusal
# would mislead.  DELETE-ACCOUNT -f also deletes the directory its registration
# points at, so it runs BEFORE the directory exists and never after.
DELETE-ACCOUNT -f "$(basename "$ACCT")" >/dev/null 2>&1 || true
rm -rf "$ACCT"
CREATE-ACCOUNT "$ACCT" >/dev/null 2>&1 || {
    echo "::error::CREATE-ACCOUNT $ACCT was refused" >&2
    exit 1
}

# AND PROVE IT IS ONE.  Measured on 6.2.1.1: CREATE-ACCOUNT leaves bin, lib and
# MD]D.  A fixture that cannot say what it built is the thing being fixed.
for part in "MD]D" bin lib; do
    [ -e "$ACCT/$part" ] || {
        echo "::error::$ACCT has no $part -- that is a directory, not an account" >&2
        exit 1
    }
done

cd "$ACCT"
# This drives jsh directly rather than logging in, so nothing has set it:
# JEDIFILENAME_MD is how a session finds the account's MD.
export JEDIFILENAME_MD="$ACCT"
# A non-interactive shell has no TERM, and an MV session with no TERM can
# produce empty output -- which reads as a code regression, with nothing in the
# failure saying "TERM" (mv_git#199).
export TERM="${TERM:-vt100}"

printf 'CREATE-FILE BP 1 11 TYPE=UD\nQUIT\n' | jsh >/dev/null 2>&1 || true
[ -d "$ACCT/BP" ] || {
    echo "::error::CREATE-FILE BP did not create $ACCT/BP" >&2
    exit 1
}

# The package's own two functions, mapfield's one, and the test itself.
cp "$MAPFIELD/BP/MAPFIELD" "$ACCT/BP/MAPFIELD"
cp "$SRC/BP/JSONENCODE" "$ACCT/BP/JSONENCODE"
cp "$SRC/BP/JSONDECODE" "$ACCT/BP/JSONDECODE"
cp "$SRC/tests/JSON.ESCAPES" "$ACCT/BP/JSON.ESCAPES"

# CATALOG the three FUNCTIONs so DEFFUN can resolve them; the test is a PROGRAM
# and is RUN from its object, so it needs no catalog of its own.
#
# jBASE REPORTS A FAILED COMPILE ON STDOUT AND CARRIES ON, leaving the old
# object (or none) in place, and a piped session's exit status is the status of
# its last command only.  So neither the status nor the absence of a message
# says this worked: the log is the evidence, and it is read below.
{
    printf 'BASIC BP MAPFIELD\nCATALOG BP MAPFIELD\n'
    printf 'BASIC BP JSONENCODE\nCATALOG BP JSONENCODE\n'
    printf 'BASIC BP JSONDECODE\nCATALOG BP JSONDECODE\n'
    printf 'BASIC BP JSON.ESCAPES\nRUN BP JSON.ESCAPES\n'
    printf 'QUIT\n'
} | jsh >"$LOG" 2>&1 || true

echo "---- jsh session ----"
cat "$LOG"
echo "---------------------"

# ASSERT A POSITIVE FACT, NOT THE ABSENCE OF A BAD ONE.  JSON.ESCAPES prints one
# `ok=` line per case and then FAILURES=0, so requiring five `ok=1` and no
# `ok=0` fails a session that compiled nothing and ran nothing -- which is what
# a bare `grep FAILURES=0` would call a pass on an empty log.  Unanchored
# because a piped jsh session can put its prompt on the front of a line.
fail=0
oks=$(grep -c 'ok=1' "$LOG" || true)
bad=$(grep -c 'ok=0' "$LOG" || true)
[ "$oks" -eq 5 ] || { echo "::error::expected 5 passing JSON.ESCAPES cases, saw $oks"; fail=1; }
[ "$bad" -eq 0 ] || { echo "::error::$bad JSON.ESCAPES case(s) failed"; fail=1; }
grep -q 'FAILURES=0' "$LOG" || { echo "::error::JSON.ESCAPES did not report FAILURES=0"; fail=1; }

if [ "$fail" -ne 0 ]; then
    # What the account actually ended up with.  A cataloged FUNCTION lands in
    # the account's lib as an object; if the compile failed there is nothing
    # there, and that distinguishes "did not build" from "built and gave the
    # wrong answer" without having to guess the layout in an assertion.
    echo "---- $ACCT/lib and bin ----"
    find "$ACCT/lib" "$ACCT/bin" -type f 2>/dev/null | sed 's/^/  /' || true
    echo "---------------------------"
    exit 1
fi

echo "jbase-ci: JSON.ESCAPES passed all 5 cases in $ACCT"
