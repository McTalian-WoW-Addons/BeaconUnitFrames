# BeaconUnitFrames conventions

## Structure

- Every file opens `local addonName = select(1, ...)` then `local ns = select(2, ...)` — never the `local addonName, ns = ...` shorthand.
- Build components with `ns.NewFeatureModule(name)`; never register modules by hand.
- Compose reusable option behaviors as mixins under `options/mixins/`; `options/typeDefaults/` bundles mixins for common component kinds (fontString, statusBar, texture).
- Each `unitFrames/<type>/` subtree mirrors the same internal shape: frame, portrait, name, level, health/, power/, indicators/.
- New files: register in the nearest `index.xml` Include/Script chain — `wow-build-tools` follows that chain, not a directory scan.

## WoW API

- BUF reskins and repositions Blizzard's existing frames (PlayerFrame, TargetFrame, ...) rather than spawning new frames.
- All state lives in AceDB (`ns.db`); never call `SetWidth`/`SetFont`/`SetPoint` etc. outside a `RefreshConfig()` path — the DB is the single source of truth, applied on every refresh cascade.
- Confirm API signatures, events, and enums per flavor with `/wow-dev:wow-api`.

## Strings

- User-facing text goes through `ns.L["Key"]` (AceLocale-3.0), with the key added to `BeaconUnitFrames/locale/enUS.lua`.
- Non-English locale files (`deDE.lua`, `esES.lua`, `frFR.lua`, etc.) hold translations only.
- `make i18n_check` finds keys referenced in code but missing from a locale file; `make i18n_fmt` sorts/organizes locale files.

## Testing

- No automated test suite; `make test-ci` is a placeholder that only creates the coverage directory for CI.
- Validate changes with `make boot_sim` (builds, then simulates a client login to surface Lua load errors) and an in-game `/reload`.

## Packaging

- Only `BeaconUnitFrames/` ships; root-level `.scripts/`, `.github/`, `CONTRIBUTING.md`, `docs/` are dev-only.
- `git add` new files before `make dev`/`make build` — `wow-build-tools` skips untracked files silently.
- Type commits by whether they touch the packaged `BeaconUnitFrames/` dir; see `/wow-dev:git-workflow`.
