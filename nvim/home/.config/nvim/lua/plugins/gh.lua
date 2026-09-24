return {
  {
    "ldelossa/gh.nvim",
    dependencies = {
      "ldelossa/litee.nvim",
    },
    config = function()
      require("litee.lib").setup()
      require("litee.gh").setup({
        keymaps = {
          open_pull_panel = "<leader>gP",
          edit_issue = "<leader>gi",
        },
      })
    end,
    keys = {
      { "<leader>gP", desc = "Open PR panel" },
      { "<leader>ge", "<cmd>GHEditPR<cr>", desc = "Edit PR description" },
    },
  },
}
