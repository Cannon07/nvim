return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    -- Helper: clean up diff windows and fugitive buffers
    local function cleanup_diff(exclude_win)
      -- Close diff windows
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= exclude_win and vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
      -- Wipe fugitive buffers
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("^fugitive://") then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end
      -- Clear any existing DiffAutoClose autocmds
      pcall(vim.api.nvim_del_augroup_by_name, "DiffAutoClose")
    end

    -- Per-window diff highlight namespaces
    -- HEAD (original) side: red tones — lines here were "removed" in the working copy
    local head_ns = vim.api.nvim_create_namespace("diff_head_hl")
    vim.api.nvim_set_hl(head_ns, "DiffAdd", { bg = "#4c2e2e" })
    vim.api.nvim_set_hl(head_ns, "DiffDelete", { bg = "#2e4c2e" })
    vim.api.nvim_set_hl(head_ns, "DiffChange", { bg = "#4c3a2e" })
    vim.api.nvim_set_hl(head_ns, "DiffText", { bg = "#5c3030" })

    -- Working copy side: green tones — lines here were "added" or changed
    local working_ns = vim.api.nvim_create_namespace("diff_working_hl")
    vim.api.nvim_set_hl(working_ns, "DiffAdd", { bg = "#2e4c2e" })
    vim.api.nvim_set_hl(working_ns, "DiffDelete", { bg = "#4c2e2e" })
    vim.api.nvim_set_hl(working_ns, "DiffChange", { bg = "#2e3c4c" })
    vim.api.nvim_set_hl(working_ns, "DiffText", { bg = "#3e5c3e" })

    -- Helper: equalize diff windows in remaining space after neo-tree
    local function equalize_diff_panes()
      local diff_wins = {}
      local neo_tree_width = 0
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[buf].filetype
          if ft == "neo-tree" then
            neo_tree_width = vim.api.nvim_win_get_width(win)
          elseif vim.wo[win].diff then
            table.insert(diff_wins, win)
          end
        end
      end
      if #diff_wins >= 2 then
        local separators = #diff_wins + (neo_tree_width > 0 and 0 or -1)
        local diff_width = math.floor((vim.o.columns - neo_tree_width - separators) / #diff_wins)
        for _, win in ipairs(diff_wins) do
          vim.api.nvim_win_set_width(win, diff_width)
        end
      end
    end

    require("neo-tree").setup({
      sources = { "filesystem", "buffers", "git_status" },
      source_selector = {
        winbar = true,
        content_layout = "center",
        sources = {
          { source = "filesystem", display_name = " Files" },
          { source = "buffers", display_name = " Buffers" },
          { source = "git_status", display_name = " Git" },
        },
      },
      event_handlers = {
        {
          event = "neo_tree_window_after_open",
          handler = function()
            vim.defer_fn(equalize_diff_panes, 50)
          end,
        },
        {
          event = "neo_tree_window_after_close",
          handler = function()
            vim.defer_fn(equalize_diff_panes, 50)
          end,
        },
      },
      filesystem = {
        window = {
          mappings = {
            ["<cr>"] = "open_clean",
            ["o"] = "open_clean",
          },
        },
        commands = {
          open_clean = function(state)
            local node = state.tree:get_node()
            if node.type ~= "file" then
              -- For directories, use built-in toggle
              require("neo-tree.sources.filesystem.commands").toggle_node(state)
              return
            end
            cleanup_diff()
            require("neo-tree.sources.common.commands").open(state, require("neo-tree.utils").open_file)
          end,
        },
      },
      git_status = {
        window = {
          mappings = {
            ["<cr>"] = "open_diff",
            ["D"] = "open_diff",
            ["o"] = "open",
            ["s"] = "git_add_file",
            ["u"] = "git_unstage_file",
            ["S"] = "git_add_all",
            ["r"] = "git_revert_file",
          },
        },
        commands = {
          open_diff = function(state)
            local node = state.tree:get_node()
            if node.type ~= "file" then return end

            local neo_tree_win = vim.api.nvim_get_current_win()
            local neo_tree_width = vim.api.nvim_win_get_width(neo_tree_win)

            -- Clean up: close all non-neo-tree windows and wipe fugitive buffers
            cleanup_diff(neo_tree_win)
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if win ~= neo_tree_win then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end

            -- Open the file in a new split to the left of neo-tree
            vim.cmd("leftabove vsplit " .. vim.fn.fnameescape(node.path))
            -- Fugitive's Gvdiffsplit works synchronously (no buffer attachment needed)
            vim.cmd("Gvdiffsplit")
            -- Restore neo-tree width and equalize diff panes
            vim.api.nvim_win_set_width(neo_tree_win, neo_tree_width)
            -- Make the HEAD/original side (left split) readonly
            vim.cmd("wincmd h")
            local head_win = vim.api.nvim_get_current_win()
            local head_buf = vim.api.nvim_get_current_buf()
            equalize_diff_panes()
            vim.cmd("setlocal readonly")
            vim.cmd("setlocal nomodifiable")
            -- Apply per-window diff highlights (red for HEAD, green for working copy)
            vim.api.nvim_win_set_hl_ns(head_win, head_ns)
            vim.cmd("wincmd l")
            local working_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_hl_ns(working_win, working_ns)

            -- Auto-close both diff sides when either is closed with :q
            local group = vim.api.nvim_create_augroup("DiffAutoClose", { clear = true })
            vim.api.nvim_create_autocmd("WinClosed", {
              group = group,
              pattern = tostring(working_win),
              once = true,
              callback = function()
                pcall(vim.api.nvim_win_close, head_win, true)
                pcall(vim.api.nvim_buf_delete, head_buf, { force = true })
                pcall(vim.api.nvim_del_augroup_by_id, group)
              end,
            })
            vim.api.nvim_create_autocmd("WinClosed", {
              group = group,
              pattern = tostring(head_win),
              once = true,
              callback = function()
                if vim.api.nvim_win_is_valid(working_win) then
                  vim.api.nvim_win_call(working_win, function()
                    vim.cmd("diffoff")
                  end)
                end
                pcall(vim.api.nvim_del_augroup_by_id, group)
              end,
            })
          end,
        },
      },
    })

    vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal right<CR>", {})
    vim.keymap.set("n", "<C-d>", ":Neotree git_status reveal right<CR>", {})
  end,
}
