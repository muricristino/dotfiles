return {
  {
    "github/copilot.vim",
    -- cmd (não InsertEnter): o copilot.vim sobe o language server ao carregar
    -- mesmo com copilot_enabled=0 — só carrega quando :Copilot for invocado
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
