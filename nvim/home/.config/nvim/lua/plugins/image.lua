return {
  "3rd/image.nvim",
  event = "VeryLazy",
  -- no build: the magick_cli processor doesn't need the luarock, and building via
  -- luarocks/hererocks fails on machines without a Lua toolchain (e.g. fresh Linux)
  build = false,
  opts = {
    -- Ghostty speaks the Kitty image protocol
    backend = "kitty",
    -- use the already-installed `magick` binary (CLI), no luarock needed
    processor = "magick_cli",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = true,
    -- needed to render inside tmux (allow-passthrough is already on)
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
  },
}
