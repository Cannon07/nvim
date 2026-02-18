local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("vim-options")
require("lazy").setup("plugins")

-- Custom modules for Claude Code integration
require("custom.hotreload").setup()
require("custom.directory-watcher").start()

-- Yank utilities
local yank = require("custom.yank")
vim.keymap.set("v", "<leader>yr", yank.yank_with_relative_path, { desc = "Yank with relative path" })
vim.keymap.set("n", "<leader>yp", yank.yank_relative_path, { desc = "Yank relative path" })
