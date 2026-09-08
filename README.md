# json

JSON encode/decode for MultiValue — the **MAPFIELD projection** is the point:
Pick dynamic arrays (`@AM`/`@VM` associations) become sensible JSON (arrays of
objects) and back, driven by a [`mapfield`](https://github.com/mvx-lang/mapfield)
spec.

`BP/JSONENCODE` and `BP/JSONDECODE` are portable BASIC — the same projection on
**UniData, UniVerse and jBASE**, installed by cataloging the two functions.
Depends on **mapfield**, the `%MAP%` spec builder.

**mvx is not a target.** It used to be: this package shipped a native extension
(`src/mvxjson.c`) that mvx built into its system account from a submodule. That
codec now lives in the mvx runtime itself, so `JSONENCODE`/`JSONDECODE` are
built in there with no package to install (mvx-lang/mvx#169). The interface is
identical either way — `J = JSONENCODE(REC, SPEC)` — so portable code does not
care which system it is running on.
