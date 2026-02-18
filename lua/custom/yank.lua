local M = {}

function M.yank_with_relative_path()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local rel_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  local header = rel_path .. ":" .. start_line .. "-" .. end_line
  local content = header .. "\n" .. table.concat(lines, "\n")

  vim.fn.setreg("+", content)
  vim.fn.setreg('"', content)
  vim.notify("Yanked with path: " .. header, vim.log.levels.INFO)
end

function M.yank_relative_path()
  local rel_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
  vim.fn.setreg("+", rel_path)
  vim.fn.setreg('"', rel_path)
  vim.notify("Yanked path: " .. rel_path, vim.log.levels.INFO)
end

return M
