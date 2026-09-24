-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- <leader>uC: toggle GitHub Copilot on/off
vim.keymap.set("n", "<leader>uC", function()
  -- pcall: com o plugin lazy (cmd = "Copilot"), a função só existe após o
  -- primeiro :Copilot enable — que é o que o else dispara
  local ok, enabled = pcall(vim.fn["copilot#Enabled"])
  if ok and enabled == 1 then
    vim.cmd("Copilot disable")
    vim.notify("Copilot: OFF", vim.log.levels.WARN, { title = "Copilot" })
  else
    vim.cmd("Copilot enable")
    vim.notify("Copilot: ON", vim.log.levels.INFO, { title = "Copilot" })
  end
end, { desc = "Toggle Copilot" })

-- <leader>e: open explorer or toggle focus between explorer and editor
-- <leader>E: close explorer
-- persists the last navigated cwd across toggles
vim.g._explorer_cwd = nil

local function explorer_toggle()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if not explorer then
    Snacks.explorer.open(vim.g._explorer_cwd and { cwd = vim.g._explorer_cwd } or nil)
  elseif explorer:is_focused() then
    vim.g._explorer_cwd = explorer:cwd()
    vim.cmd("wincmd p")
  else
    if vim.g._explorer_cwd and vim.g._explorer_cwd ~= explorer:cwd() then
      explorer:set_cwd(vim.g._explorer_cwd)
    end
    explorer:focus()
  end
end

vim.keymap.set("n", "<leader>e",  explorer_toggle, { desc = "Toggle Explorer Focus" })
vim.keymap.set("n", "<leader>fe", explorer_toggle, { desc = "Toggle Explorer Focus" })
vim.keymap.set("n", "<leader>fE", explorer_toggle, { desc = "Toggle Explorer Focus" })

-- Copy file path to clipboard
-- <leader>yp: copy relative path
-- <leader>yP: copy absolute path
-- <leader>yf: copy filename only
vim.keymap.set("n", "<leader>yp", function() vim.fn.setreg("+", vim.fn.fnamemodify(vim.fn.expand("%"), ":.")) end, { desc = "Copy relative path" })
vim.keymap.set("n", "<leader>yP", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy absolute path" })
vim.keymap.set("n", "<leader>yf", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Copy filename" })

-- Edit PR description in a new buffer
-- <leader>gp: open PR body, edit, save and submit with :w
vim.keymap.set("n", "<leader>gp", function()
  local tmp = vim.fn.tempname() .. ".md"
  vim.fn.system("gh pr view --json body -q .body | sed 's/\\r//' > " .. tmp)
  vim.cmd("edit " .. tmp)
  vim.cmd("set fileformat=unix")
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = 0,
    once = true,
    callback = function()
      vim.fn.system("gh pr edit --body-file " .. tmp)
      vim.notify("PR description updated!", vim.log.levels.INFO)
    end,
  })
end, { desc = "Edit PR description" })

-- Undo/Redo with Cmd+Z / Cmd+Shift+Z (Mac-native feel)
vim.keymap.set("n", "<D-z>", "u", { desc = "Undo" })
vim.keymap.set("n", "<D-S-z>", "<C-r>", { desc = "Redo" })

-- Override LazyVim default <leader>gd (Snacks git_diff) with DiffviewOpen
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen origin/main...HEAD<cr>", { desc = "Diff vs origin/main" })

-- Copy to clipboard when mouse selection is released (works in terminal buffers too)
vim.keymap.set("v", "<LeftRelease>", "y", { silent = true, desc = "Copy on mouse select" })

vim.keymap.set("n", "<leader>E", function()
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if explorer then
    explorer:close()
  end
end, { desc = "Close Explorer" })

-- Cmd+V chega como <C-v> (keybind do Ghostty). Só em insert/cmdline: em normal
-- e visual o <C-v> continua sendo o visual-block.
vim.keymap.set("i", "<C-v>", "<C-r><C-o>+", { desc = "Paste clipboard" })
vim.keymap.set("c", "<C-v>", "<C-r><C-o>+", { desc = "Paste clipboard" })
