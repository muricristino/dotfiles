return {
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
    explorer = {
      enabled = true,
      width = 15,
      hidden = true,
      ignored = true,
    },
    picker = {
      toggles = {
        hidden = "",
        ignored = "",
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              width = 25,
              min_width = 25,
            },
          },
          win = {
            input = { title = "" },
            list  = { title = "" },
          },
        },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc() == 0 then
          Snacks.explorer.open()
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        vim.api.nvim_set_hl(0, "SnacksExplorerDir", { fg = "#7daea3", bold = true })
        vim.api.nvim_set_hl(0, "SnacksExplorerFile", { fg = "#d4be98" })
        vim.api.nvim_set_hl(0, "SnacksExplorerHidden", { fg = "#a9b665" })
        vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = "#7daea3", bold = true })
        vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = "#d4be98" })
      end,
    })
  end,
}
