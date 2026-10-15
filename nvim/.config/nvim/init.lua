-- Use the terminal palette even before plugins are installed.
vim.opt.termguicolors = false
vim.cmd.colorscheme("terminal-ansi")

-- Bootstrap lazy.nvim, LazyVim, and the imported non-theme configuration.
require("config.lazy")
vim.opt.spell = false
