-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.clipboard = "unnamedplus"

-- Handle extended keys from ghostty/tmux
vim.o.ttimeoutlen = 10
vim.o.timeoutlen = 500

-- Allow Cmd+V for paste in tmux
vim.keymap.set('i', '<M-v>', '<C-r>+', { noremap = true })
