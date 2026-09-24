return {
  -- Treesitter: syntax highlighting for JSX/TSX/JS/TS
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "javascript",
        "typescript",
        "tsx",
        "json",
        "html",
        "css",
      })
    end,
  },

  -- LSP: TypeScript/JavaScript language server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ts_ls = {
          handlers = {
            ["textDocument/documentHighlight"] = function() end,
          },
        },
        eslint = {},       -- ESLint as LSP (lint)
      },
    },
  },

  -- Mason: auto-install LSP servers
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "typescript-language-server",
        "eslint-lsp",
        "prettierd",         -- formatter
        "js-debug-adapter",
      })
    end,
  },

  -- Auto-fix eslint on save
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
      },
      setup = {
        eslint = function()
          local group = vim.api.nvim_create_augroup("LazyVimEslintFix", { clear = true })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = group,
            pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
            callback = function(args)
              if #vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" }) == 0 then
                return
              end

              vim.lsp.buf.code_action({
                apply = true,
                filter = function(client)
                  return client.name == "eslint"
                end,
                context = {
                  only = { "source.fixAll.eslint" },
                  diagnostics = {},
                },
              })
            end,
          })
        end,
      },
    },
  },
}
