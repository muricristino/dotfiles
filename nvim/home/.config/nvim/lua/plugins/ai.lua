return {
  -- Supermaven AI autocomplete
  {
    "supermaven-inc/supermaven-nvim",
    -- cmd (not InsertEnter): otherwise sm-agent starts in every nvim even with
    -- inline completion off — only loads when you invoke it
    cmd = { "SupermavenStart", "SupermavenToggle", "SupermavenStatus" },
    opts = {
      disable_inline_completion = true,  -- off by default; :SupermavenStart to enable
      keymaps = {
        accept_suggestion = "<Tab>",   -- accept with Tab
        clear_suggestion = "<C-]>",    -- dismiss
        accept_word = "<C-j>",         -- accept one word
      },
      ignore_filetypes = { "TelescopePrompt" },
      color = {
        suggestion_color = "#808080",  -- grey ghost text
      },
    },
  },
}
