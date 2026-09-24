-- Scrollbar decorado na borda: thumb (noção de tamanho do arquivo) +
-- marcadores de cursor, busca, diagnostics, git e marks. Estilo Cursor/VSCode.
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
