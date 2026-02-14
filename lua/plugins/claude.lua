return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("claudecode").setup({
      auto_start = true,
      terminal = {
        split_side = "left",
        split_width_percentage = 0.30,
        provider = "auto",
        auto_close = true,
      },
    })

    -- Zoom toggle: maximize current window or restore original width
    local zoomed = false
    local saved_widths = {}

    local function toggle_zoom()
      if zoomed then
        -- Restore saved widths
        for win, width in pairs(saved_widths) do
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_width(win, width)
          end
        end
        saved_widths = {}
        zoomed = false
      else
        -- Save all window widths before zooming
        saved_widths = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          saved_widths[win] = vim.api.nvim_win_get_width(win)
        end
        vim.cmd("wincmd |")
        vim.cmd("wincmd _")
        zoomed = true
      end
    end

    vim.keymap.set("n", "<leader>az", toggle_zoom, { desc = "Toggle zoom Claude" })
    vim.keymap.set("t", "<leader>az", function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), "n", false)
      vim.schedule(toggle_zoom)
    end, { desc = "Toggle zoom Claude" })
  end,
  keys = {
    { "<leader>a",  nil,                                   desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>",                 desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",            desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",        desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>",      desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>",      desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",            desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>",             mode = "v", desc = "Send to Claude" },
    { "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",          desc = "Add file from tree",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" } },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",       desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",         desc = "Deny diff" },
  },
}
