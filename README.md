# Neovim Configuration

Personal Neovim configuration using **lazy.nvim** as the plugin manager.

## Structure

- `init.lua` — Entry point: bootstraps lazy.nvim, loads options and plugins
- `lua/vim-options.lua` — Core Vim settings (indentation, clipboard, leader key)
- `lua/plugins/*.lua` — Individual plugin specs, auto-discovered by lazy.nvim

## Plugins

| Plugin | Purpose |
|--------|---------|
| catppuccin | Color scheme |
| lualine | Status line (dracula theme) |
| neo-tree | File explorer (right side) |
| telescope | Fuzzy finder |
| nvim-treesitter | Syntax highlighting and indentation |
| nvim-lspconfig + mason | LSP support with auto-install |
| nvim-cmp + LuaSnip | Autocompletion with snippets |
| none-ls | Formatters and linters |
| gitsigns + vim-fugitive | Git integration |
| vim-tmux-navigator | Seamless tmux/nvim split navigation |

## LSP Servers

ts_ls, solargraph, html, lua_ls, gopls, dartls

## Key Bindings

Leader key: `Space`

| Key | Action |
|-----|--------|
| `<C-p>` | Find files (Telescope) |
| `<leader>fg` | Live grep (Telescope) |
| `<C-n>` | Toggle file explorer |
| `K` | LSP hover |
| `<leader>gd` | Go to definition |
| `<leader>gr` | Find references |
| `<leader>ca` | Code action |
| `<leader>gf` | Format buffer |
| `<leader>gp` | Preview git hunk |
| `<leader>gt` | Toggle git line blame |

## Setup

1. Clone this repo to `~/.config/nvim/`
2. Open Neovim — lazy.nvim will bootstrap and install all plugins automatically
3. Run `:Lazy sync` to ensure everything is up to date
