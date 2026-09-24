local function update_term_title(term)
  if not term.window or not vim.api.nvim_win_is_valid(term.window) then return end

  local pid = vim.b[term.bufnr] and vim.b[term.bufnr].terminal_job_pid
  local fallback_folder = vim.fn.fnamemodify(term.dir or vim.fn.getcwd(), ":t")

  local function apply_label(folder, cmd)
    if not term.window or not vim.api.nvim_win_is_valid(term.window) then return end
    local terms = require("toggleterm.terminal").get_all(true)
    local pos = 1
    for i, t in ipairs(terms) do
      if t.id == term.id then pos = i; break end
    end
    local label = cmd ~= ""
      and string.format("  %d/%d  %s  %s ", pos, #terms, folder, cmd)
      or  string.format("  %d/%d  %s ", pos, #terms, folder)
    term.display_name = label
    pcall(vim.api.nvim_win_set_config, term.window, { title = label, title_pos = "center" })
  end

  if not pid then
    apply_label(fallback_folder, "")
    return
  end

  local sh_cmd = string.format([[
    child=$(pgrep -P %d 2>/dev/null | head -1)
    cwd=$(lsof -a -p %d -d cwd 2>/dev/null | awk 'NR>1 {print $NF; exit}')
    cmd=""
    if [ -n "$child" ]; then
      cmd=$(ps -o comm= -p "$child" 2>/dev/null | awk -F/ '{print $NF}')
    fi
    printf '%%s\t%%s' "$cmd" "$cwd"
  ]], pid, pid)

  vim.system({ "sh", "-c", sh_cmd }, { text = true }, function(result)
    vim.schedule(function()
      local out = (result.stdout or ""):gsub("\n", "")
      local tab = out:find("\t", 1, true)
      local cmd = tab and out:sub(1, tab - 1) or ""
      local cwd = tab and out:sub(tab + 1) or ""
      local folder = cwd ~= "" and vim.fn.fnamemodify(cwd, ":t") or fallback_folder
      apply_label(folder, cmd)
    end)
  end)
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    direction = "float",
    open_mapping = [[<M-t>]],
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    float_opts = {
      border = "rounded",
      title_pos = "center",
    },
    winbar = { enabled = false },
    on_open = function(term)
      vim.schedule(function() update_term_title(term) end)
      vim.fn.timer_start(1000, function()
        vim.schedule(function() update_term_title(term) end)
      end, { ["repeat"] = -1 })
    end,
  },
  keys = {
    {
      "<leader>t",
      function() vim.cmd(vim.v.count1 .. "ToggleTerm") end,
      mode = "n",
      desc = "Toggle terminal",
    },
    {
      "<M-t>",
      function() vim.cmd(vim.v.count1 .. "ToggleTerm") end,
      mode = "n",
      desc = "Toggle terminal",
    },
    {
      "<leader>T",
      "<cmd>TermSelect<cr>",
      mode = "n",
      desc = "List terminals",
    },
    {
      "<leader>tl",
      "<cmd>TermSelect<cr>",
      mode = "n",
      desc = "List terminals",
    },
    {
      "<leader>tn",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        local next_id = #terms + 1
        vim.cmd(next_id .. "ToggleTerm")
      end,
      mode = "n",
      desc = "New terminal",
    },
    {
      "<M-]>",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        if #terms == 0 then return end
        local current = require("toggleterm.terminal").get_focused_id()
        local next_id = (current % #terms) + 1
        vim.cmd(terms[next_id].id .. "ToggleTerm")
      end,
      mode = { "n", "t" },
      desc = "Next terminal",
    },
    {
      "<M-[>",
      function()
        local terms = require("toggleterm.terminal").get_all(true)
        if #terms == 0 then return end
        local current = require("toggleterm.terminal").get_focused_id()
        local prev_id = ((current - 2) % #terms) + 1
        vim.cmd(terms[prev_id].id .. "ToggleTerm")
      end,
      mode = { "n", "t" },
      desc = "Previous terminal",
    },
  },
}
