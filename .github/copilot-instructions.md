# BeaconUnitFrames — AI Coding Instructions

> Additional context loads automatically for unit frame files (`.github/instructions/unitframes.instructions.md`), options files (`options.instructions.md`), mixin files (`mixins.instructions.md`), locale files (`locale.instructions.md`), core files (`core.instructions.md`), build/packaging files (`build.instructions.md`), and all addon files for WoW UI source navigation (`wow-ui-source.instructions.md`).

## Project Overview

WoW addon (Lua) for the Midnight expansion using the **Ace3 framework**. Modifies and skins the 8 default unit frames (Player, Target, Pet, Focus, ToT, ToFocus, Party, Boss). Entry point: `BeaconUnitFrames/core/core.lua`.

## WoW API Reference

The workspace includes `../wow-ui-source` as a second folder (see `BeaconUnitFrames.code-workspace`). This is the authoritative reference for the WoW API — frame structures, widget templates, global functions, and FrameXML layouts. **Always consult `wow-ui-source` before assuming the shape of any Blizzard frame or API.** Lua diagnostics are disabled on that folder; it is read-only reference material, never to be edited.

## Namespace Pattern

All files share a single addon namespace (`ns`) via WoW's vararg addon mechanism:

```lua
---@class BUFNamespace
local ns = select(2, ...)
```

Never use globals — attach everything to `ns`. LuaLS annotations (`---@class`, `---@field`, etc.) are used throughout; maintain them on new code.

## Feature Module Pattern

`ns.NewFeatureModule()` (defined in `options/options.lua:96`) wraps Ace3's `ns.BUF:NewModule()` and mixes in `ProfileDbBackedHandler`, `AceHook-3.0`, and `AceEvent-3.0`. Follow this structure:

```lua
local BUFMyComponent = ns.NewFeatureModule("BUFMyComponent")
BUFMyComponent.configPath = "unitFrames.player.myComponent"   -- DB path
BUFMyComponent.dbDefaults = { enabled = true, width = 200 }
ns.dbDefaults.profile.unitFrames.player.myComponent = BUFMyComponent.dbDefaults
BUFMyComponent.optionsTable = { type = "group", ... }
ns.options.args.myComponent = BUFMyComponent.optionsTable     -- register options
function BUFMyComponent:RefreshConfig() ... end               -- REQUIRED, errors if missing
ns.BUFUnitFrames:RegisterFrame(BUFMyComponent)                -- only for top-level frames
```

`RegisterFrame` is defined in `unitFrames/unitFrames.lua:27`. `RefreshConfig` is called on every registered frame by `UnitFrames:RefreshConfig()` and throws a hard error if missing.

`FrameInit` (optional) is called manually inside a module's `RefreshConfig` behind an `if not self.initialized` guard, using the parent frame's function with `self` passed explicitly (e.g., `BUFBoss.FrameInit(self)`). It handles one-time setup like `customRelativeToOptions` initialization, with self-anchoring automatically excluded.

## DB Access

Use `DbGet` / `DbSet` / `DbClear` — never access `ns.db` directly in feature modules. Keys use dotted notation relative to `configPath`:

```lua
self:DbGet("width")          -- reads ns.db.profile.unitFrames.player.myComponent.width
self:DbSet("width", value)
self:DbClear("width")        -- resets to default
```

## File Loading

Files are loaded via `index.xml` — not auto-discovered. **Adding a new `.lua` file requires a `<Script file="..."/>` entry in the nearest `index.xml`**, or it silently will not load in-game.

## Localization

All user-facing strings must use `ns.L["Key"]`. Add new keys to `locale/enUS.lua` under the current version's `--#region vX.Y.Z` block. Run `make i18n_check` to validate completeness before building. Run `make i18n_fmt` to auto-generate placeholder entries in other locale tables.

## Directory Conventions

- `unitFrames/<frame>/` — one subdirectory per unit frame type, each mirroring the same sub-component layout (`frame`, `name`, `level`, `portrait`, `health/`, `power/`, `indicators/`)
- `options/mixins/` — cross-cutting option+behavior pairs
- `options/typeDefaults/` — reusable default config blocks for component types (statusBar, fontString, texture)
- `libs/` — vendored libraries; **do not modify**; managed via `.pkgmeta` and fetched by `wow-build-tools` during build
