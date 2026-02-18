local M = {}

local uv = vim.uv or vim.loop
local watchers = {}
local debounce_timer = nil
local DEBOUNCE_MS = 200

local ignore_patterns = {
  "^%.git/",
  "^%.git$",
  "node_modules/",
  "%.swp$",
  "%.swo$",
  "~$",
  "%.tmp$",
}

local function should_ignore(path)
  for _, pattern in ipairs(ignore_patterns) do
    if path:match(pattern) then
      return true
    end
  end
  return false
end

local function reload_buffers()
  vim.schedule(function()
    -- Reload visible unmodified buffers
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified and vim.bo[buf].buftype == "" then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! checktime")
          end)
        end
      end
    end

  end)
end

local function debounced_reload()
  if debounce_timer then
    debounce_timer:stop()
  end
  debounce_timer = uv.new_timer()
  debounce_timer:start(DEBOUNCE_MS, 0, function()
    debounce_timer:stop()
    debounce_timer:close()
    debounce_timer = nil
    reload_buffers()
  end)
end

local function watch_path(path)
  local handle = uv.new_fs_event()
  if not handle then return end

  handle:start(path, { recursive = true }, function(err, filename)
    if err then return end
    if filename and should_ignore(filename) then return end
    debounced_reload()
  end)

  table.insert(watchers, handle)
end

function M.start()
  M.stop()

  local cwd = uv.cwd()
  if cwd then
    watch_path(cwd)
  end

  -- Also watch .git directory for index changes
  local git_dir = cwd and (cwd .. "/.git")
  if git_dir and uv.fs_stat(git_dir) then
    watch_path(git_dir)
  end
end

function M.stop()
  for _, handle in ipairs(watchers) do
    if handle and not handle:is_closing() then
      handle:stop()
      handle:close()
    end
  end
  watchers = {}
end

return M
