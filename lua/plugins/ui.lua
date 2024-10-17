return {
  {
    "alexghergh/nvim-tmux-navigation",
    config = function()
      require "configs.tmux-navigation"
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
  },

  {
    "nvim-telescope/telescope-ui-select.nvim",
    lazy = false,
    -- requires = {
    --   "nvim-telescope/telescope.nvim",
    -- },
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {
              -- even more opts
            },

            -- pseudo code / specification for writing custom displays, like the one
            -- for "codeactions"
            -- specific_opts = {
            --   [kind] = {
            --     make_indexed = function(items) -> indexed_items, width,
            --     make_displayer = function(widths) -> displayer
            --     make_display = function(displayer) -> function(e)
            --     make_ordinal = function(e) -> string
            --   },
            --   -- for example to disable the custom builtin "codeactions" display
            --      do the following
            --   codeactions = false,
            -- }
          },
        },
      }
      -- To get ui-select loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      require("telescope").load_extension "ui-select"
    end,
  },

  {
    "aznhe21/actions-preview.nvim",
    -- requires = {
    --   "neovim/nvim-lspconfig",
    --   "nvim-telescope/telescope.nvim",
    -- },
    lazy = false,
    config = function()
      local hl = require "actions-preview.highlight"
      require("actions-preview").setup {
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
        highlight_command = {
          -- hl.delta(),
          -- You may need to specify "--no-gitconfig" since it is dependent on
          -- the gitconfig of the project by default.
          hl.delta "delta --side-by-side",

          -- Highlight diff using diff-so-fancy: https://github.com/so-fancy/diff-so-fancy
          -- The arguments are optional, in which case ("diff-so-fancy", "less -R")
          -- is assumed to be specified. The existence of less is optional.
          hl.diff_so_fancy(),

          -- Highlight diff using diff-highlight included in git-contrib.
          -- The arguments are optional; the first argument is assumed to be
          -- "diff-highlight" and the second argument is assumed to be
          -- `{ colordiff = "colordiff", pager = "less -R" }`. The existence of
          -- colordiff and less is optional.
          hl.diff_highlight(),
        },
      }
      vim.keymap.set(
        { "v", "n" },
        "<leader>cc",
        require("actions-preview").code_actions,
        { noremap = true, desc = "Code actions w/ preview" }
      )
    end,
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        integrations = {
          bufferline = false,
          gitsigns = true,
          mason = true,
          neogit = true,
          cmp = true,
          dap = true,
          dap_ui = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
            inlay_hints = {
              background = true,
            },
          },
          treesitter = true,
          telescope = {
            enabled = true,
            style = "nvchad",
          },
          gitgutter = true,
          lsp_trouble = true,
          which_key = true,
        },
      }
    end,
  },
}
