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
