return {
  "3rd/image.nvim",
  event = "VeryLazy",
  -- sem build: o processor magick_cli dispensa o luarock, e o build via
  -- luarocks/hererocks falha em máquinas sem toolchain Lua (ex.: Linux limpo)
  build = false,
  opts = {
    -- Ghostty fala o protocolo de imagem do Kitty
    backend = "kitty",
    -- usa o binario `magick` (CLI) ja instalado, sem precisar de luarock
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
    -- necessario pra renderizar dentro do tmux (allow-passthrough ja esta on)
    tmux_show_only_in_active_window = true,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
  },
}
