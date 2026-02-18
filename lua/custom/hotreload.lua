local M = {}

function M.setup()
  vim.o.autoread = true
  vim.o.updatetime = 300

  local group = vim.api.nvim_create_augroup("HotReload", { clear = true })

  vim.api.nvim_create_autocmd(
    { "FocusGained", "TermLeave", "BufEnter", "WinEnter", "CursorHold", "CursorHoldI" },
    {
      group = group,
      command = "checktime",
    }
  )

  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    callback = function()
      vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
    end,
  })
end

return M
