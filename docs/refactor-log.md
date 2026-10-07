# Refactor and Neovim 0.12 migration

Work started on 2026-10-07 on `codex/nvim-refactor-0.12`.

## Scope and preservation

Restructure the configuration, upgrade the dependencies needed for Neovim
0.12.5, and correct small, verified bugs. Keep every existing plugin, setting,
mapping, tool list, and inactive configuration available. Conform remains in
use during this stage; removing it is a separate decision.

File moves change ownership, not the available feature set. Changes to loading
order or behavior belong in separate commits from the structural moves.
Rustaceanvim and Haskell Tools major upgrades are deferred because they require
their own configuration migration.

## Baseline

`65b8315` records the seven files already modified when this work began. It
includes the existing plugin lock updates, Lean configuration, Just and Tombi
server entries, clipboard mapping, formatter setting, and Mason edits. Those
changes were made before this refactor.

The original editor is `/Users/filup/.local/opt/nvim-0.11.7/bin/nvim`.
Keep that installation and its plugin/parser data available for rollback.
Neovim 0.12 tests must use separate data, cache, and state directories until
the upgraded configuration passes its checks.

## Validation

Before and after each structural step, compare the resolved Lazy plugin
inventory against the baseline and compile every Lua file. For the migration,
exercise startup, Treesitter highlighting and Markdown injections, Telescope
previews, and the configured LSP registration in the isolated 0.12 environment.
Interactive language-server and debugger behavior still needs a real project
and a user session; automated smoke tests do not establish that coverage.

## Steps

1. Snapshot the existing edits (`65b8315`).
2. Document the preservation boundary and rollback plan.
3. Split plugin specifications and language configuration by ownership.
4. Correct small, verified configuration bugs.
5. Upgrade Treesitter and Telescope for Neovim 0.12 and test isolated assets.

Details and test results are appended as each step is completed.

### Plugin and language ownership

- `plugins/init.lua` imports the nested language specifications explicitly.
- `plugins/formatting.lua` owns Conform and None-ls; both remain configured.
- `plugins/completion.lua` owns LazyDev, CMP additions, and the existing Blink
  configuration; their original activation behavior is retained.
- `plugins/lsp.lua` and `plugins/treesitter.lua` own the NvChad overrides.
- `plugins/ai.lua` owns both Copilot integrations.
- `plugins/languages/` contains Python, Rust, Haskell, Lean, Typst, Markdown,
  and D2 specifications. The former root Rust file was moved here.
- `configs/lsp/` contains the shared registration, server settings, Rust and
  Haskell callbacks, and Typst helpers. The two existing `configs/lspconfig`
  require paths forward to their new owners.
- Generic editing, documentation generation, diagnostics, UI, community
  imports, debugging, commands, mappings, and inactive configuration files
  remain available in their existing dedicated modules.

The final ownership pass separates the remaining generic programming specs:
`plugins/documentation.lua` owns Neogen, `plugins/diagnostics.lua` owns Trouble
and TODO comments, and `plugins/tools.lua` retains the former Lua utility
specification for nvim-nio. These are source moves with no option or trigger
changes.

Validation: all Lua files compile; all 66 resolved Lazy plugin names,
repositories, version constraints, activation triggers, and key definitions
match the baseline. Separate extraction checks compared the moved editor and
language settings and callbacks. The lockfile retains all 67 original entries,
including entries not present in the resolved specification; no cleanup was
performed.

### Small configuration fixes

- Rust and Haskell settings are assigned from their plugin `init` callbacks,
  before the integrations read them. NvChad attachment support is resolved
  later when a server actually attaches; Haskell mappings use a local setter.
- Just uses the native `(bufnr, on_dir)` root callback. Harper is registered as
  `harper_ls`, retaining the server's `harper-ls` settings key.
- Pest and Lean retain their plugin integrations as the owners of their LSPs;
  invalid duplicate generic registrations no longer shadow those integrations.
- Lua initialization handles missing or empty workspace folders while still
  respecting project `.luarc.json` and `.luarc.jsonc` files.
- Copilot LSP is enabled after its runtime files are available, and its
  companion spec uses Lazy's `dependencies` field.
- Notify uses supported `opts`; Presence receives its existing options once
  instead of being configured twice.
- The venv statusline module is under NvChad's `ui.statusline` schema, with its
  renderer required only when the module renders.

Validation: repeatable isolated Neovim checks passed for early globals,
preserved Rust/Haskell mappings, Just's callback, Harper settings, Pest/Lean
ownership, standalone and project Lua initialization, Copilot enable order,
and Notify/Presence configuration through Lazy's real configuration loader.
Theme selection and the existing mapping order are preserved.

### Decisions deliberately deferred

- Conform removal and choosing the replacement formatting pipeline.
- Copilot Tab/Esc versus NvChad shortcuts, and the DAP `df`/`ds` conflicts.
- Typst project-root selection and the scope of its pin/unpin shortcuts.
- The obsolete `VenvSelectCached` shortcut and inactive legacy configuration
  files; none were deleted.
- Activating dormant None-ls diagnostics, Blink, tmux navigation, or standalone
  theme integrations.
- Rustaceanvim/Haskell Tools major upgrades, diagnostic filter changes, and
  debugger dependency/listener cleanup.

### Neovim 0.12 dependency migration

Target: [Neovim 0.12.5](https://github.com/neovim/neovim/releases/tag/v0.12.5),
recorded in `.nvim-version`.

Only two plugin lock entries change:

| Dependency | Neovim 0.11 rollback | Neovim 0.12 target |
| --- | --- | --- |
| nvim-treesitter | `master`, `cf12346a3414fa1b06af75c79faebe7f76df080a` | `main`, `e289100ff98969e118c702199d88b764ce9e7fdf` |
| Telescope | 0.1.8, `a0bbec21143c7bc5f8bb02e0005fa0b982edc026` | [0.2.1](https://github.com/nvim-telescope/telescope.nvim/releases/tag/v0.2.1), `3333a52ff548ba0a68af6d8da1e54f9cd96e9179` |

The Treesitter rewrite needs a separate
[Treesitter CLI >= 0.26.1](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md).
The isolated build used the official
[0.27.0 CLI](https://github.com/tree-sitter/tree-sitter/releases/tag/v0.27.0).
The other 65 lock entries retain their baseline revisions.

`configs/profile.lua` selects independent assets from the running editor
version. With the default local paths:

| Asset | Neovim 0.11 | Neovim 0.12 |
| --- | --- | --- |
| Plugin directory | `~/.local/share/nvim/lazy` | `~/.local/share/nvim/lazy-0.12` |
| Lockfile | `lazy-lock-0.11.json` | `lazy-lock.json` |
| Parser/query assets | Original legacy locations, including the Treesitter plugin | `~/.local/share/nvim/site-0.12` |

The legacy lockfile is an exact copy of the initial 67-entry lock. Treesitter
chooses the matching API and branch for each editor. On 0.12, Lazy retains the
prepared runtime path so it cannot reintroduce the old `site` directory.

Treesitter loads eagerly, uses the rewrite's `setup` API on 0.12, and keeps the
legacy setup API on 0.11. Unsupported inherited lazy command/event handlers are
cleared. The explicit `TSInstallAll` command is registered after NvChad's
autocommands so NvChad cannot replace the version-aware implementation.
Startup does not download parsers. The original list of 42 languages remains
unchanged; the 0.12 install command additionally includes the existing D2
integration. `TSUpdate` remains the build/update command.

The conflicting Telescope `0.1.x` constraint in the Python dependency was
removed; `plugins/telescope.lua` now owns the 0.2.1 version constraint. The
legacy lock still restores the original Telescope for rollback.

A fresh Base46 cache is generated when its defaults file is absent. This
allows a clean isolated profile to start rather than assuming an existing
theme cache.

The isolated parser build installed 48 languages: the requested 43, plus five
dependencies selected by Treesitter. Modern smoke checks passed parser loading
and highlight queries for all 43 requested languages, fenced Lua injection in
Markdown, node text extraction, Telescope Treesitter highlighting, Markdown
LSP floating previews, the final install command, and native LSP registration.
The old editor is checked with the same plugin-preservation and registration
checks using its legacy installation API.

The reusable smoke check runs after normal configuration startup:

```sh
NVIM_LOG_FILE=/dev/null nvim --headless -i NONE -n \
  '+luafile /Users/filup/.config/nvim/scripts/smoke.lua'
```

These checks establish startup and configuration compatibility. They do not
replace project-level testing of Python virtual environments/debugging,
Rust/Haskell servers, Typst preview, authenticated Copilot, and interactive UI
behavior.
