return {
  -- Visual search & replace across the whole project (uses ripgrep + GNU sed)
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    opts = {
      -- macOS ships BSD sed which breaks Spectre's replace; use gnu-sed (gsed)
      replace_engine = {
        ["sed"] = {
          cmd = "gsed",
          args = nil,
        },
      },
    },
    keys = {
      { "<leader>sr", function() require("spectre").toggle() end, desc = "Spectre: replace in project" },
      { "<leader>sr", function() require("spectre").open_visual() end, mode = "v", desc = "Spectre: replace selection" },
      { "<leader>sp", function() require("spectre").open_file_search({ select_word = true }) end, desc = "Spectre: replace in current file" },
    },
  },
}
