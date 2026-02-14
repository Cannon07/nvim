vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.wo.relativenumber = true
vim.api.nvim_set_option("clipboard","unnamed")
vim.g.mapleader = " "

vim.opt.diffopt:append("context:6")

-- Diff highlighting: green for additions, red for deletions
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2e4c2e" })       -- green bg for added lines
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#4c2e2e" })    -- red bg for deleted lines
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2e3c4c" })    -- blue bg for changed lines
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#3e5c3e" })      -- brighter green for changed text within a line
  end,
})
