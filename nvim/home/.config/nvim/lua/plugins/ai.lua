return {
  -- Supermaven AI autocomplete
  {
    "supermaven-inc/supermaven-nvim",
    -- cmd (não InsertEnter): senão o sm-agent sobe em todo nvim mesmo com
    -- inline completion desligado — só carrega quando você chamar
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
