return function(on_attach)
  vim.g.haskell_tools = {
    ---@type ToolsOpts
    tools = {
      repl = {
        prefer = "stack",
        auto_focus = true,
      },
    },
    ---@type HaskellLspClientOpts
    hls = {
      ---@param client number The LSP client ID.
      ---@param bufnr number The buffer number
      ---@param ht HaskellTools = require('haskell-tools')
      on_attach = function(client, bufnr, ht)
        on_attach(client, bufnr)

        local opts = { noremap = true, silent = true, buffer = bufnr }

        -- code lens
        map("n", "<leader>cl", vim.lsp.codelens.run, vim.tbl_extend("force", opts, { desc = "Run Code Lens" }))

        -- Hoogle search for the type signature of the definition under the cursor
        vim.keymap.set(
          "n",
          "<space>hs",
          ht.hoogle.hoogle_signature,
          vim.tbl_extend("force", opts, { desc = "Hoogle Signature" })
        )

        -- Evaluate all code snippets
        vim.keymap.set(
          "n",
          "<space>ea",
          ht.lsp.buf_eval_all,
          vim.tbl_extend("force", opts, { desc = "Evaluate All Code Snippets" })
        )

        -- Toggle a GHCi repl for the current package
        vim.keymap.set("n", "<leader>rr", ht.repl.toggle, vim.tbl_extend("force", opts, { desc = "Toggle GHCi Repl" }))

        -- Toggle a GHCi repl for the current buffer
        vim.keymap.set("n", "<leader>rf", function()
          ht.repl.toggle(vim.api.nvim_buf_get_name(0))
        end, vim.tbl_extend("force", opts, { desc = "Toggle GHCi Repl for Buffer" }))

        vim.keymap.set("n", "<leader>rq", ht.repl.quit, vim.tbl_extend("force", opts, { desc = "Quit GHCi Repl" }))
      end,
    },
  }
end
