local M = {}

-- Track the diff tab so we can close it later
local diff_tab = nil
local diff_bufs = {}
local diff_augroup = nil

-- Per-window diff highlight namespaces (matches neo-tree conventions)
-- CURRENT (original) side: red tones — lines here were "removed" in the proposed version
local current_ns = vim.api.nvim_create_namespace("claude_diff_current_hl")
vim.api.nvim_set_hl(current_ns, "DiffAdd", { bg = "#4c2e2e" })
vim.api.nvim_set_hl(current_ns, "DiffDelete", { bg = "#2e4c2e" })
vim.api.nvim_set_hl(current_ns, "DiffChange", { bg = "#4c3a2e" })
vim.api.nvim_set_hl(current_ns, "DiffText", { bg = "#5c3030" })

-- PROPOSED side: green tones — lines here were "added" or changed
local proposed_ns = vim.api.nvim_create_namespace("claude_diff_proposed_hl")
vim.api.nvim_set_hl(proposed_ns, "DiffAdd", { bg = "#2e4c2e" })
vim.api.nvim_set_hl(proposed_ns, "DiffDelete", { bg = "#4c2e2e" })
vim.api.nvim_set_hl(proposed_ns, "DiffChange", { bg = "#2e3c4c" })
vim.api.nvim_set_hl(proposed_ns, "DiffText", { bg = "#3e5c3e" })

local function read_file_lines(path)
  local lines = {}
  local f = io.open(path, "r")
  if f then
    for line in f:lines() do
      table.insert(lines, line)
    end
    f:close()
  end
  return lines
end

function M.show_diff(original_path, proposed_path, real_file_path)
  -- Close any existing diff first
  M.close_diff()

  local display_name = real_file_path or "unknown"

  -- Detect filetype from the real file path for syntax highlighting
  local ft = vim.filetype.match({ filename = real_file_path }) or ""

  -- Open a new tab for the diff
  vim.cmd("tabnew")
  diff_tab = vim.api.nvim_get_current_tabpage()

  -- Left side: CURRENT (original file content)
  local orig_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(orig_buf, 0, -1, false, read_file_lines(original_path))
  vim.api.nvim_buf_set_name(orig_buf, "[CURRENT] " .. display_name)
  vim.bo[orig_buf].buftype = "nofile"
  vim.bo[orig_buf].bufhidden = "wipe"
  vim.bo[orig_buf].swapfile = false
  vim.bo[orig_buf].modifiable = false
  if ft ~= "" then
    vim.bo[orig_buf].filetype = ft
  end

  local orig_win = vim.api.nvim_get_current_win()
  vim.wo[orig_win].winbar = "%#DiagnosticError# CURRENT %* " .. display_name
  vim.api.nvim_win_set_hl_ns(orig_win, current_ns)
  vim.cmd("diffthis")

  -- Right side: PROPOSED (what Claude wants to write)
  -- Use "rightbelow" to ensure the new split is to the RIGHT of current
  vim.cmd("rightbelow vsplit")
  local prop_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, prop_buf)
  vim.api.nvim_buf_set_lines(prop_buf, 0, -1, false, read_file_lines(proposed_path))
  vim.api.nvim_buf_set_name(prop_buf, "[PROPOSED] " .. display_name)
  vim.bo[prop_buf].buftype = "nofile"
  vim.bo[prop_buf].bufhidden = "wipe"
  vim.bo[prop_buf].swapfile = false
  vim.bo[prop_buf].modifiable = false
  if ft ~= "" then
    vim.bo[prop_buf].filetype = ft
  end

  local prop_win = vim.api.nvim_get_current_win()
  vim.wo[prop_win].winbar = "%#DiagnosticWarn# PROPOSED %* " .. display_name
  vim.api.nvim_win_set_hl_ns(prop_win, proposed_ns)
  vim.cmd("diffthis")

  diff_bufs = { orig_buf, prop_buf }

  -- Show the full file (like VS Code diff) — open all folds after diffthis
  for _, win in ipairs({ orig_win, prop_win }) do
    vim.wo[win].foldenable = true
    vim.wo[win].foldmethod = "diff"
    vim.wo[win].foldlevel = 999
    vim.wo[win].foldcolumn = "0"
  end

  -- Equalize window widths to 50/50
  vim.cmd("wincmd =")

  -- Re-equalize when terminal is resized (e.g. tmux pane zoom/unzoom)
  diff_augroup = vim.api.nvim_create_augroup("ClaudeDiffResize", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = diff_augroup,
    callback = function()
      if diff_tab and vim.api.nvim_tabpage_is_valid(diff_tab)
        and vim.api.nvim_get_current_tabpage() == diff_tab then
        vim.cmd("wincmd =")
      end
    end,
  })

  -- Jump to first diff change
  vim.cmd("normal! ]c")
end

function M.close_diff()
  if diff_tab and vim.api.nvim_tabpage_is_valid(diff_tab) then
    local wins = vim.api.nvim_tabpage_list_wins(diff_tab)
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end

  for _, buf in ipairs(diff_bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  if diff_augroup then
    pcall(vim.api.nvim_del_augroup_by_id, diff_augroup)
    diff_augroup = nil
  end

  diff_tab = nil
  diff_bufs = {}
end

return M
