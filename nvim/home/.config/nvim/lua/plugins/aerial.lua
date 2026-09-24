return {
  "stevearc/aerial.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    -- { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Symbol outline" },
    { "[s", "<cmd>AerialPrev<cr>", desc = "Previous symbol" },
    { "]s", "<cmd>AerialNext<cr>", desc = "Next symbol" },
  },
  opts = {
    attach_mode = "cursor",
    layout = { width = 35 },
    show_guides = true,
  },
}
