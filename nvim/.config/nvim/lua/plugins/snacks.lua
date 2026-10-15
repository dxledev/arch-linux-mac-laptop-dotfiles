local function configure_files(options)
  options.exclude = vim.list_extend(options.exclude or {}, require("config.cmake").picker_excludes(options.cwd))
  return options
end

return {
  {
    "nvim-mini/mini.icons",
    opts = {
      file = {
        Makefile = { glyph = "", hl = "MiniIconsYellow" },
      },
      extension = {
        tpp = { glyph = "󰬁", hl = "MiniIconsAzure" },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            config = configure_files,
            hidden = true,
            no_ignore = true,
          },
        },
      },
    },
  },
}
