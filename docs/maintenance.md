# Editor and tool maintenance

Run these commands from the configuration root:

```sh
just                      # List recipes
just plan                 # Read-only tool inventory and commands
just check                # Offline installer regression checks
just update-nvim           # Download and activate the latest stable Neovim
just update-nvim 0.12.5    # Select a particular stable release
just update-tools         # Install missing tools and update installed tools
just update               # Neovim plus external tools
just update-nix           # Separate, whole-system Nix update and rebuild
```

Every update recipe asks for confirmation. `just --yes update` explicitly skips
that prompt. A declined confirmation makes no changes. The helpers use Python
3.12 or newer, Neovim, and the package managers already installed on this Mac.
They do not bootstrap package managers or replace them with another provider.

## Installation methods

The inventory was checked against executable paths, Homebrew receipts, Cargo
receipts, GHCup/Elan installations, Mason receipts, and the existing Nix flake.
Checksums of the manual Haskell executables also match the Stack snapshot copies.

| Tools | Installation and update method |
| --- | --- |
| Neovim, Tree-sitter CLI | Official GitHub release downloads into `~/.local/opt`; activate through `~/.local/bin` symlinks |
| Node, VS Code HTML/CSS/JSON servers, Tombi, Typst, Typstyle, D2, Latexindent | Homebrew install/upgrade of the named formulae |
| ASM and Pest language servers | Cargo install with the stable toolchain and upstream lockfile |
| Rust, Cargo, Rust Analyzer, Rustfmt, Clippy, Rust sources | Rustup stable update and component installation |
| GHC, Cabal, Stack, HLS | GHCup downloads; select its latest releases |
| Hoogle, Fast-tags, Fourmolu, Hlint, Haskell debugger tools | Stack downloads/builds into the existing `~/.local/bin` directory |
| Elan, default stable Lean/Lake | Elan's own update and stable toolchain download; project `lean-toolchain` files retain their selections |
| Mason tool list and Tinymist/Docker Compose/JSON servers | Existing Mason installation; refresh its registry and wait for every installer to finish |
| Latexmk | Existing MacTeX/TeX Live package manager, using `sudo` |
| Search, Git, terminal and other Nix packages | Already declared in `~/.config/nix/flake.nix`; verify availability, update through the separate Nix recipe |
| `open`, `xmllint`, compiler, Make | Existing macOS/Xcode tools; verify availability |

Your `lua/opts/mason.lua` list was not connected to an automatic installer.
The maintenance command reads it explicitly and maps `typos_lsp` to Mason's
`typos-lsp` package. It also maintains the three configured servers missing from
that list. Existing overlapping installations are preserved: for example,
Fourmolu/debug adapters have both Stack copies and active Mason copies, and
some language servers have both Homebrew/Cargo and Mason installations.

Lazy still owns plugin downloads. Treesitter owns parser downloads through the
existing `:TSInstallAll` and `:TSUpdate` commands. Typst Preview downloads its
Websocat dependency. These are not duplicated by the external-tool updater.
Python and other available runtime prerequisites remain under their current
owners; the updater does not replace the python.org framework installation.
The maintenance process includes `/Library/TeX/texbin` in its own PATH. If normal
Neovim sessions cannot find `latexmk`, add that directory to your shell's PATH too.

## Downloads and failure behavior

Manual installers resolve the requested release through GitHub's API and verify
the asset's official SHA256 digest before extraction. They validate the staged
executable's version before switching a symlink. Older version directories are
retained, and the active Neovim version is recorded in `.nvim-version`.
The documented 0.11 rollback installation and plugin/parser data remain available.

A failed Neovim update stops the combined update. Independent tool failures are
reported while the remaining steps run; the final exit status is nonzero if any
step failed. Mason has a 30-minute timeout and waits for completion rather than
exiting immediately after starting downloads. Provider updates are not one
transaction: a later failure does not undo earlier successful updates.

Homebrew may also update dependencies of the named formulae, following its normal
[dependency rules](https://docs.brew.sh/FAQ#why-does-brew-upgrade-formula-or-brew-install-formula-also-upgrade-a-bunch-of-other-stuff).
The separate Nix recipe updates the existing flake lock and uses the same
`sudo darwin-rebuild switch --flake` method as your current Nix update script;
it affects the entire Nix system.

The existing TeX Live installation is **2024**. Its maintenance step uses the
matching frozen `tlnet-final` repository, as described by the
[TeX Live installation documentation](https://tug.org/texlive/acquire.html).
It maintains that year's Latexmk package; installing a newer MacTeX distribution
is a separate upgrade. A different installed year requires updating the manifest's
year and matching repository before this recipe will run its TeX step.

## Extending the installer

Edit `scripts/tools.json`:

- Add formula names under `brew` for Homebrew tools.
- Add a `manual` record for another verified GitHub `.tar.gz` or single-binary
  `.gz` release, with its repository, asset template, architecture mapping and
  archive root when applicable. Its binary must support `--version`.
- Add a named `commands` record with argument arrays for another native manager.
  Arguments run directly, without shell evaluation. Available placeholders are
  `{home}`, `{bin}`, `{stack_resolver}`, and `{nix_directory}`.
- Add Mason packages to the existing `lua/opts/mason.lua` list or `mason.extra`;
  use `mason.aliases` for name differences and `mason.exclude` for packages you
  intentionally maintain elsewhere.
- Add availability checks under `managed` for declaratively installed or system
  tools. Update their own configuration to install them, rather than introducing
  a competing package manager.

Stack uses the latest LTS snapshot for the manually installed tools, overriding
the old `lts-21.23` global snapshot for this invocation without editing it.
Set `stack_resolver` in the manifest or run
`NVIM_STACK_RESOLVER=lts-21.23 just update-tools` to select a compatible snapshot.
Some older Haskell debugger packages may require an older snapshot; a build
failure is reported without replacing their existing executable.

Set `NVIM_TOOLS_TIMEOUT` to change Mason's timeout in seconds. Run `just plan`
after manifest changes to review the resulting selection and commands.
