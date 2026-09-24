return {
  -- Auto save
  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      enabled = true,
      debounce_delay = 1000, -- save 1 second after you stop typing
    },
  },
}
