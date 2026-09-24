local function set_diff_colors()
  vim.opt.fillchars:append("diff: ")
  vim.api.nvim_set_hl(0, "DiffAdd",    { bg = "#1c2b1c" })
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#2b1c1c", fg = "#5c3030" })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1c1c2b" })
  vim.api.nvim_set_hl(0, "DiffText",   { bg = "#2d4a1e", bold = true })
  vim.api.nvim_set_hl(0, "DiffviewDiffAddAsDelete", { bg = "#3d1515" })
  vim.api.nvim_set_hl(0, "DiffviewDiffAdd",         { bg = "#1c3a1c" })
  vim.api.nvim_set_hl(0, "DiffviewDiffDelete",      { bg = "#3d1515" })
end

return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Diff vs origin/main" },
      { "<leader>gD", "<cmd>DiffviewOpen<cr>",                    desc = "Diff (index)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>",           desc = "File History" },
      { "<leader>gx", "<cmd>DiffviewClose<cr>",                   desc = "Close Diff" },
      { "<leader>gs", "<cmd>DiffviewToggleFiles<cr>",             desc = "Toggle diff sidebar" },
    },
    config = function(_, opts)
      local actions = require("diffview.actions")
      require("diffview").setup(vim.tbl_deep_extend("force", opts, {
        keymaps = {
          view = {
            { "n", "gs", actions.toggle_files,   { desc = "Toggle file panel" } },
            { "n", "gf", actions.focus_files,    { desc = "Focus file panel" } },
            { "n", "ge", actions.goto_file_edit, { desc = "Edit file" } },
          },
          file_panel = {
            { "n", "gs", actions.toggle_files, { desc = "Toggle file panel" } },
            { "n", "o",  actions.select_entry, { desc = "Open file in diff" } },
          },
          file_history_panel = {
            { "n", "gs", actions.toggle_files, { desc = "Toggle file panel" } },
            { "n", "o",  actions.select_entry, { desc = "Open file in diff" } },
          },
        },
      }))
    end,
    opts = {
      enhanced_diff_hl = true,
      hooks = {
        diff_buf_win_enter = function(bufnr, winid, ctx)
          -- "b" is the right side (working tree), "a" is the old version (read-only)
          if ctx.symbol == "b" then
            vim.bo[bufnr].modifiable = true
          end
        end,
      },
      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = false,
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = set_diff_colors })
      set_diff_colors()
    end,
  },
}
