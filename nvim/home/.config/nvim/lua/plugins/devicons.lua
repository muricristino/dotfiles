return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    priority = 1000,
    opts = { default = true },
  },

  -- Re-enable mini.icons as a fallback shim (LazyVim expects it)
  {
    "nvim-mini/mini.icons",
    enabled = true,
    opts = {},
    init = function()
      -- use nvim-web-devicons for file icons
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
