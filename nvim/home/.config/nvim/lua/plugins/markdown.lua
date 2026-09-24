return {
  {
    "MeanderingProgrammer/markdown.nvim",
    name = "render-markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "Avante", "octo" },
    opts = {
      file_types = { "markdown", "Avante", "octo" },
      render_modes = { "n", "c" },
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        sign = false,
        style = "full",
        left_pad = 1,
        right_pad = 1,
        border = "thin",
      },
      checkbox = {
        enabled = true,
        unchecked = {
          icon = "☐ ",
          highlight = "NonText",
        },
        checked = {
          icon = "☑ ",
          highlight = "DiagnosticOk",
        },
      },
    },
  },
}
