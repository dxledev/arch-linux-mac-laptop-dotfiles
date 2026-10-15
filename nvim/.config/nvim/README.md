# Neovim configuration

Imported from `~/builds/arch-linux-legion-dotfiles/nvim/.config/nvim`, keeping
the LazyVim extras, plugins, snippets, keymaps, filetype rules, and queries.

The `terminal-ansi` colorscheme uses only the terminal's ANSI slots 0–15.
`lua/config/palette.lua` names those slots; the terminal supplies their actual
colors. Normal text, floating windows, and the tab bar use the terminal's
default foreground/background. Syntax, diagnostics, Git signs, completion,
pickers, lualine, and bufferline share this palette. `termguicolors` stays off.
Change the terminal's color theme to recolor Neovim. Reload with
`:colorscheme terminal-ansi` if needed.

The Arch theme plugins, custom colorschemes, theme watcher, wallpaper palette,
and external border-color integration are omitted.

On first launch, lazy.nvim downloads the plugins. GitHub access is required;
if bootstrap fails, Neovim still opens with the ANSI colorscheme and retries
on the next launch. Once installed, `:Lazy restore` uses the copied non-theme
plugin versions in `lazy-lock.json`.

The imported C++ debugger expects `codelldb` and `~/bin/dev/float-dap-terminal`.
