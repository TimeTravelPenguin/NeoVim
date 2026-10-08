**This repo is supposed to be used as config by NvChad users!**

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!

# Local configuration

The plugin and language layout, migration steps, verification results, and
rollback instructions are recorded in [docs/refactor-log.md](docs/refactor-log.md).

The target editor version is recorded in `.nvim-version`. Neovim 0.11.7 remains
supported as a rollback path with its own lockfile and plugin directory.

Use `:Hex 64` or `:Hex 0x64` to jump to line 100. Hex digits and the optional
`0x` prefix are case-insensitive. The line number must be between 1 and the
current buffer's line count; invalid input shows an error without moving the cursor.

Run `just plan` to review the external-tool installation methods, `just update-nvim`
to download and install Neovim, or `just update` to update Neovim and its tools.
Update recipes ask for confirmation. See [maintenance](docs/maintenance.md) for
the tool inventory, separate Nix update, and how to extend the installer.
