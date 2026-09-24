return {
  {
    "github/copilot.vim",
    -- cmd (not InsertEnter): copilot.vim starts the language server on load
    -- even with copilot_enabled=0 — only loads when :Copilot is invoked
    cmd = "Copilot",
    config = function()
      vim.g.copilot_enabled = 0  -- off by default; toggle with <leader>uC
      vim.g.copilot_no_tab_map = true
      vim.keymap.set("i", "<Tab>", 'copilot#Accept("\\<Tab>")', {
        expr = true,
        replace_keycodes = false,
      })
      vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)")
      vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)")
      vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)")

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          pcall(vim.fn["copilot#Server#Stop"])
        end,
      })
    end,
  },
}
