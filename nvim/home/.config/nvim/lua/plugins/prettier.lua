return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      css = { "prettierd" },
      html = { "prettierd" },
      json = { "prettierd" },
      markdown = { "prettierd" },
      elixir = { "mix" },
      eelixir = { "mix" },
      heex = { "mix" },
      ruby = { "rubocop" },
    },
    format_on_save = false,
  },
  keys = {
    {
      "<C-s>",
      function()
        require("conform").format({ async = false, lsp_fallback = true })
        vim.cmd("write")
      end,
      mode = { "n", "i", "v" },
      desc = "Format and save",
    },
  },
}
