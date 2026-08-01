# json

JSON encode/decode for MultiValue — the **MAPFIELD projection** is the point:
Pick dynamic arrays (`@AM`/`@VM` associations) become sensible JSON (arrays of
objects) and back, driven by a [`mapfield`](https://github.com/mvx-lang/mapfield)
spec. Cross-platform:

- **mvx** — native (`src/mvxjson.c` → `libmvxext_json`), `JSONENCODE`/`JSONDECODE`
  exports; fast. Built into mvx (`MVX_PACKAGES`).
- **udt** — portable BASIC (`udt/JSONDECODE`, `udt/JSONENCODE`), the same
  projection in pure BASIC; installs by cataloging the functions.

Depends on **mapfield** (the `%MAP%` spec builder) on udt; on mvx `MAPFIELD` is a
compiler builtin.

See [`udt/README.md`](udt/README.md) for the BASIC port and the UDO/CallC
robustness roadmap.
