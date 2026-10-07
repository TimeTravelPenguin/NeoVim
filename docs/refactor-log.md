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
