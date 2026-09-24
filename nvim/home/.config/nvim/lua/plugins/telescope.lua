return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files({ hidden = true, no_ignore = false }) end, desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "Grep String" },
      {
        "<leader>fp",
        function()
          local base = vim.fn.systemlist("git merge-base origin/main HEAD")[1] or "origin/main"
          require("telescope.builtin").git_files({
            prompt_title = "PR Files (vs " .. base:sub(1, 7) .. ")",
            git_command = { "git", "diff", "--name-only", "--diff-filter=ACMR", base .. "...HEAD" },
          })
        end,
        desc = "Find PR Files (vs origin/main)",
      },
    },
    opts = {
      defaults = {
        layout_config = {
          horizontal = {
            preview_width = 0.45,
            width = 0.95,
            height = 0.85,
          },
        },
        path_display = { "filename_first" },
        file_ignore_patterns = {
          "node_modules/",
          ".git/",
          ".webpack_cache/",
          "dist/",
          "build/",
          ".next/",
        },
        mappings = {
          i = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
          n = {
            ["j"] = require("telescope.actions").move_selection_next,
            ["k"] = require("telescope.actions").move_selection_previous,
            ["h"] = require("telescope.actions").close,
            ["l"] = require("telescope.actions").select_default,
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
    end,
  },
}
