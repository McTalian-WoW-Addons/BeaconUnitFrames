# BeaconUnitFrames

WoW addon (Lua, Ace3): skins/repositions Blizzard's default unit frames (not oUF-style). Flavors from `BeaconUnitFrames/BeaconUnitFrames.toc` `## Interface`. Shared workflow: `wow-dev` plugin skills.

## Commands

`make help` lists targets. Checks: `/wow-dev:run-checks`. Only via make: `make dev`, `make watch`, `make build`, `make boot_sim` (builds then simulates a client login to catch load errors), `make toc_update`, `make i18n_fmt`, `make lua_deps`; `./trunk fmt && ./trunk check`.

## Conventions

- Every file: `local addonName = select(1, ...)` then `local ns = select(2, ...)`.
- Feature modules via `ns.NewFeatureModule(name)`; mixes in DbGet/DbSet/DbClear, AceHook-3.0, AceEvent-3.0.
- All state lives in the DB; never call `SetWidth`/`SetFont`/`SetPoint` etc. outside a `RefreshConfig()` path.
- Strings via `ns.L["Key"]` + key in `BeaconUnitFrames/locale/enUS.lua`.
- New files: register in the nearest `index.xml` Include/Script chain and `git add` before building.
  Full list: `docs/agent/conventions.md`.

## Docs

- `CONTRIBUTING.md` — directory layout, load order, feature module pattern, adding a frame type.
- `.github/instructions/*.instructions.md` — per-area detail (core, mixins, locale, options, unitframes, build).
- `/wow-dev:wow-api` — API/event/enum ground truth (`~/code/wow-ui-source`).
