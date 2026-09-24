-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Cursor shape: block in normal, pipe in insert
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"

-- Always use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Word wrap
vim.opt.wrap = true
vim.opt.linebreak = true

-- Auto reload files changed externally
vim.opt.autoread = true

-- Disable readonly mode for files
vim.opt.readonly = false
vim.opt.modifiable = true

-- Spell checking disabled globally (LazyVim enables it for markdown/text by default)
vim.opt.spell = false
vim.opt.spelllang = "pt_br,en"
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter" }, {
  pattern = "*",
  callback = function()
    vim.opt_local.spell = false
  end,
})
