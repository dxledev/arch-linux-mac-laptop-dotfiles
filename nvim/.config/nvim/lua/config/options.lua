-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.filetype.add({
  extension = {
    tpp = "cpp.tpp",
  },
})
vim.treesitter.language.register("cpp", "cpp.tpp")

vim.g.autoformat = false

-- Keep ANSI palette indices instead of emitting RGB colors.
vim.opt.termguicolors = false
