-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Elixir atoms (:ok, :error, etc.) in yellow — gruvbox-material doesn't define this group
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "@string.special.symbol", { fg = "#d3869b" })
    vim.api.nvim_set_hl(0, "@string.special.symbol.elixir", { fg = "#d3869b" })
  end,
})
vim.api.nvim_set_hl(0, "@string.special.symbol", { fg = "#d3869b" })
vim.api.nvim_set_hl(0, "@string.special.symbol.elixir", { fg = "#d3869b" })

-- Auto reload files changed externally when focusing window
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  command = "checktime",
})
