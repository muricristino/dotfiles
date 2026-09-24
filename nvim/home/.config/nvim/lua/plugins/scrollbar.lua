-- Decorated scrollbar on the edge: thumb (sense of file size) +
-- markers for cursor, search, diagnostics, git and marks. Cursor/VSCode style.
return {
  "lewis6991/satellite.nvim",
  event = "VeryLazy",
  opts = {
    current_only = false,
    winblend = 50,
    zindex = 40,
    excluded_filetypes = {
      "neo-tree",
      "snacks_dashboard",
      "snacks_picker_list",
      "snacks_picker_input",
      "lazy",
      "TelescopePrompt",
      "help",
    },
    handlers = {
      cursor = { enable = true },
      search = { enable = true },
      diagnostic = { enable = true, min_severity = vim.diagnostic.severity.HINT },
      gitsigns = { enable = true },
      marks = { enable = true, show_builtins = false },
      quickfix = { enable = true },
    },
  },
}
