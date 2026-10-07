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

### Local activation and rollback

The tested upgrade is installed and active:

- `/Users/filup/.local/bin/nvim` points to
  `/Users/filup/.local/opt/nvim-0.12.5/bin/nvim`.
- `/Users/filup/.local/bin/tree-sitter` points to
  `/Users/filup/.local/opt/tree-sitter-0.27.0/bin/tree-sitter`.
- Modern plugins and parser/query assets are installed in the dedicated
  `lazy-0.12` and `site-0.12` directories listed above.
- All 67 installed plugin commits match the modern lockfile. All 67 original
  plugin commits still match the legacy lockfile.
- The 47 generated query symlinks were relocated to the installed plugin
  directory and checked for missing targets. The active configuration does
  not depend on the temporary test profile.

The modern smoke check passed again after activation against the real
configuration and dependency paths, with temporary state/cache directories.
The corrected NvChad statusline also rendered successfully through Neovim's
statusline evaluation API.
The retained 0.11.7 editor also passed against the real legacy paths after
the final structural moves. No original editor, plugin, parser, inactive
configuration, or Conform installation was deleted.

To use the old editor immediately, run:

```sh
/Users/filup/.local/opt/nvim-0.11.7/bin/nvim
```

It selects the legacy lockfile and plugin directory automatically; no Git
checkout is required. To make that version the default again:

```sh
ln -sfn /Users/filup/.local/opt/nvim-0.11.7/bin/nvim \
  /Users/filup/.local/bin/nvim
```

To restore the pre-refactor source separately, the baseline commit is
`65b8315`. Keep the desired source and editor version aligned; the current
branch supports both versions without sharing their Treesitter assets.

### Commit trail

| Commit | Step |
| --- | --- |
| `65b8315` | Preserve the user's preexisting edits |
| `0c05099` | Record scope and rollback plan |
| `6b294ea` | Split plugin and language ownership |
| `9d6e4d0` | Fix verified LSP and plugin hook issues |
| `39dddff` | Add the tested 0.12 migration and independent profiles |
| `c250954` | Finish documentation, diagnostics, and utility ownership |

The following documentation commit records activation and final verification.

### Follow-up: Lazy sync lockfile assertion

The first user-run `:Lazy sync` exposed a gap in the initial migration checks.
The Telescope checkout had been cloned directly from release tag `v0.2.1`.
It therefore had a detached HEAD, a tag-only fetch refspec, and no
`origin/HEAD`. Lazy's lock writer needs a branch even for a version-pinned
plugin; it could not infer one and asserted in `lazy/manage/lock.lua:28`.
The writer opens the lockfile before checking each plugin, leaving the file
truncated to `{\n` when that assertion fails.

`plugins/telescope.lua` now explicitly declares `branch = "master"` alongside
`version = "0.2.1"`. Lazy still selects the same release and commit. No plugin
source or version was changed. The broken lockfile was regenerated through
Lazy's real lock writer; its 67 installed revisions were unchanged, and the
restored file matches the committed lockfile exactly.

Regression evidence:

- The real Lazy Git and lock modules reproduce the assertion against the
  detached checkout when the branch is unspecified, then save successfully
  with the explicit branch while retaining Telescope 0.2.1.
- `scripts/smoke.lua` now exercises Lazy's real lock writer against a temporary
  file, restores the manager's original state, and checks that every recorded
  plugin revision is preserved. It passes on both 0.12.5 and 0.11.7.
- The full Lazy clean/install/update/lock persistence lifecycle completed in
  physical copies of the configuration, plugins, and parsers, with isolated
  XDG directories and existing revisions held by `lockfile = true`. All tasks
  passed, no plugins were selected for removal, and all 67 lock entries match
  the resulting checkouts. Live plugin revisions were unaffected by this test.

Restart Neovim before retrying `:Lazy sync`, so the running Lazy specification
contains the new branch declaration.

### Follow-up: restore centred statusline progress

Moving the custom statusline from `base46` to the supported `ui` table made
its previously ignored order active. That order had only one `%=` alignment
separator, so LSP progress such as `cargo clippy` joined the right-aligned
modules. It also omitted the cursor position that NvChad's default displayed.

The order now places `lsp_msg` between two `%=` separators and restores the
cursor module at the end. The virtual-environment callback and all existing
modules remain present. This preserves the previous effective layout while
retaining the correctly placed custom configuration.

Neovim's native statusline evaluator and the installed NvChad renderer verify
the regression and correction on both 0.12.5 and 0.11.7. In a 200-column Rust
buffer, progress moved from column 180 back to column 97, matching the
pre-refactor footer exactly; the rendered cursor module is present too.
The user's lockfile updates from their successful Sync were left untouched.

### Follow-up: restore Copilot inline suggestions only

The user confirmed that the coloured text below the current line was suggested
replacement code and requested the previous inline-only behaviour. The earlier
loading fix made the standalone `copilot_ls` client active: its original enable
call ran before Lazy added the plugin's LSP configuration to the runtime.
Once active, `copilot-lsp` registers text-change hooks and displays next-edit
previews with deletion highlights and added virtual lines.

`plugins/ai.lua` now explicitly disables automatic activation of `copilot_ls`
and sets `copilot.lua`'s `nes.enabled` to `false`. Both plugin specifications,
their dependency relationship, and existing mappings remain present. Ordinary
inline suggestions retain automatic triggering and the existing `<C-l>`
accept-line mapping. This restores the requested behaviour without removing
either plugin. The separate server is disabled rather than relying on an
undocumented server setting: the installed plugin's text-change hooks request
and render edits without checking that setting.

The inline-only configuration follows the documented
[Copilot options](https://github.com/zbirenbaum/copilot.lua#nes-next-edit-suggestion).
Focused checks using the actual plugin specifications and installed Copilot
configuration modules pass on both 0.12.5 and 0.11.7: the standalone client is
disabled, no next-edit text-change hooks are registered, and inline suggestions
and their existing options remain enabled. The checks stub server startup, so
they do not send requests or validate authenticated completions. The full
configuration smoke checks also pass on both versions, and the user's Sync
lockfile updates remain unchanged.
Restart Neovim to stop the client and clear previews in an existing session.

### Follow-up: restore format on the first save

Conform inherited `lazy = true`, but its specification had no loading event.
In a fresh session it stayed unloaded, so its `BufWritePre` formatting hook
did not exist. `ToggleFormatOnSave` changed the intended flags but could not
activate that hook. Manually requiring Conform made subsequent saves format.
The missing trigger was also present in the pre-refactor specification.

The existing Conform specification now loads on `BufWritePre`, following the
[documented Lazy loading recipe](https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#lazy-loading-with-lazynvim).
Lazy replays the write event for the newly registered formatting group, so the
first save formats before writing to disk. Formatter choices, the 500 ms
timeout, LSP fallback, and both toggle scopes are unchanged. The installed
Conform versions still support the existing `lsp_fallback = true` option.

`ToggleFormatOnSave` without a bang toggles the global restriction;
`ToggleFormatOnSave!` toggles only the current buffer's restriction. A global
restriction takes precedence, and neither toggle resets the other scope.
The command's notification reports the flag in the scope just toggled: a
buffer-local `true` message does not override a global disable.

Isolated checks using real Lazy, Conform, and the installed StyLua reproduce
the failure and confirm that the save trigger restores first-save formatting
on both 0.12.5 and 0.11.7. They also verify exactly one Conform save hook and
the global/buffer toggle behavior against buffer contents and saved files.

The reusable `scripts/formatting-smoke.lua` check runs after normal
configuration startup and performs 18 real saves with StyLua in each editor
version. It verifies the first-save Lazy activation before requiring Conform,
both toggle scopes across two buffers, independent state and global
precedence, and matching buffer/disk contents. It uses temporary fixtures and
removes them on success. The same normal-startup first-save test fails in a
temporary configuration copy with only the new event removed, confirming the
loading trigger as the cause. The broader configuration smoke checks also
pass on both editor versions.

A separate normal-startup 0.12.5 test uses the installed Rust Analyzer and
Rustfmt in a temporary, dependency-free Cargo project with Cargo offline.
After the formatting-capable server attaches, Conform is still unloaded and
no external Rust formatter is configured. The first save formats both the
buffer and file through LSP fallback. Globally disabling formatting leaves
the next unformatted save untouched, and re-enabling it restores formatting.
No user project files or tool installations are changed by these checks.

```sh
NVIM_LOG_FILE=/dev/null nvim --headless -i NONE -n \
  '+luafile /Users/filup/.config/nvim/scripts/formatting-smoke.lua'
```

Restart Neovim to load the updated Lazy specification. The user's Sync
lockfile updates are preserved and are not part of this fix.

### Follow-up: Cargo context for Rust diagnostics

Reviewed the referenced chat, "Fix Neovim diagnostics display", and adapted
its final unapplied proposal to `configs/lsp/rust.lua`. The user selected the
draft's one-Cargo-project-per-Neovim-session approach. No firmware package
names, target triples, or project paths are hardcoded in the configuration.

At Rust Analyzer startup, the settings callback finds the Cargo manifest
above Neovim's current directory. Its generated check/build-script commands
change to that project directory before running `cargo clippy`/`cargo check`.
Cargo therefore selects the opened package and reads its normal configuration
hierarchy and toolchain, including member-local configuration that checks
launched from a workspace root miss. The commands emit JSON for Rust Analyzer
and use quoted positional arguments for paths and command names.

The nearest member/intermediate `.cargo/config` or `.cargo/config.toml` below
the workspace root is forwarded through `cargo.configPath` for supported Rust
Analyzer versions. The legacy `config` filename takes precedence when both
exist, matching Cargo. Explicit config paths and custom override commands are
preserved. Existing build-script/check options are extended instead of being
replaced, and generated overrides default to one invocation rather than
repeating the same project check for every linked workspace.

As discussed in the referenced draft, the blanket `cargo.features = "all"`
override is removed. Generated commands use Cargo's default features and
targets; they do not add `--workspace`, `--all-features`, or `--all-targets`.
Rust Analyzer's generated feature/target/extra-argument flags and `--config`
arguments do not apply to these explicit commands. Retaining the associated
settings does not make the wrappers forward them: compiler checks rely on
Cargo's normal discovery from the selected directory. Custom override
commands remain responsible for their own flags. Rust hover/code-action
mappings and the existing Clippy selection are preserved.

The session context is evaluated at server startup or settings reload.
Opening another project's files does not automatically switch it; use a
separate editor session for projects with different targets/configuration.
Cargo compiler checks read the full configuration hierarchy. Code analysis
only receives the nearest additional config file and can still miss
intermediate configuration files. The installed nightly Rust Analyzer
supports `cargo.configPath`; the older installed stable version does not.
This change does not claim universal analysis support for every Cargo setup.

Neovim 0.12 already implements `workspace/diagnostic/refresh`, and Rustaceanvim
already selects server-side Rust file watching. The older warning in the
referenced log was from a 0.11 session. No diagnostic-display, watcher,
severity, shell-limit, or formatting settings were changed for this fix.

Validation after normal configuration startup on Neovim 0.12.5 and 0.11.7:

- The existing general smoke check passes, including plugin preservation,
  lockfiles, LSP registration, and the version-specific runtime checks.
- `scripts/rust-settings-smoke.lua` passes on both versions. It checks the
  actual settings callback, member/intermediate config discovery, legacy
  filename precedence, explicit-option preservation, unchanged input tables,
  and safe handling of absent roots. It executes the generated shell commands
  against a temporary Cargo argument sink, including project paths with
  spaces, quotes, and literal shell metacharacters.
- Real Rustaceanvim/Rust Analyzer sessions pass a four-save compiler diagnostic
  cycle on each version for firmware, desktop, and standalone fixtures:
  no compiler errors, an `E0425` error, the repaired file, then another `E0425`
  error. Each cycle uses the same client and completes check progress after
  every save. Firmware uses the installed nightly toolchain and
  `thumbv7em-none-eabihf`; standalone uses installed stable. No downloads or
  edits to user projects are needed.
- Baseline settings reproduce wrong-target, missing-hierarchy, or forced
  optional-feature errors in those same fixtures on both editor versions.
- Nested Cargo configuration fixtures also confirm the analysis limitation:
  Cargo compiler checks pass, but Rust Analyzer retains a native `macro-error`
  when an intermediate configuration's `rustflags` are required. The stable
  analyzer also ignores the unsupported `cargo.configPath` setting. These
  negative checks are recorded separately from the passing compiler cycles.

Temporary integration fixtures, result JSON, and logs are retained locally
under `/private/tmp/nvim-rust-session-proof-wybiaddl`; `summary.json` records
the six before/after cases and `cargo-hierarchy-proof.json` the Cargo checks.

Run the persistent settings check after normal startup:

```sh
NVIM_LOG_FILE=/dev/null nvim --headless -i NONE -n \
  '+luafile /Users/filup/.config/nvim/scripts/rust-settings-smoke.lua'
```

Restart Neovim to load this change, launching it from the Cargo member/project
directory whose checks should run for the session. The synthetic save cycles
validate compiler diagnostic delivery and clearing; they do not establish that
every cause of intermittent stale diagnostics or resource exhaustion is fixed.

References: [Cargo configuration hierarchy](https://doc.rust-lang.org/cargo/reference/config.html#hierarchical-structure),
[Rust Analyzer overrides and config paths](https://rust-analyzer.github.io/book/configuration.html).
