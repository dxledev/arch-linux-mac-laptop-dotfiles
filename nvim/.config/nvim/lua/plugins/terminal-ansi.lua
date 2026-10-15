local p = require("config.palette")

return {
  { "LazyVim/LazyVim", opts = { colorscheme = "terminal-ansi" } },
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local theme = {}
      for mode, color in pairs({
        normal = p.blue, insert = p.green, visual = p.magenta, replace = p.red,
        command = p.yellow, terminal = p.cyan, inactive = p.bright_black,
      }) do
        theme[mode] = {
          a = { fg = p.black, bg = color, gui = "bold" },
          b = { fg = "NONE", bg = "NONE" },
          c = { fg = "NONE", bg = "NONE" },
        }
      end
      opts.options.theme = theme
      -- Avoid separators that derive new colors from RGB approximations.
      opts.options.section_separators = ""
      for _, section in pairs(opts.sections) do
        for _, component in ipairs(section) do
          if type(component) == "table" then
            if component.color then
              component.color = { fg = p.magenta, bg = "NONE" }
            end
            if component[1] == "diagnostics" then
              component.diagnostics_color = {
                error = { fg = p.red, bg = "NONE" }, warn = { fg = p.yellow, bg = "NONE" },
                info = { fg = p.blue, bg = "NONE" }, hint = { fg = p.cyan, bg = "NONE" },
              }
            elseif component[1] == "diff" then
              component.diff_color = {
                added = { fg = p.green, bg = "NONE" }, modified = { fg = p.yellow, bg = "NONE" },
                removed = { fg = p.red, bg = "NONE" },
              }
            elseif component[1] == "filetype" then
              component.colored = false
            end
          end
        end
      end
    end,
  },
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      -- Bufferline accepts a function to replace its generated RGB highlights.
      opts.highlights = function(defaults)
        local highlights = {}
        for name in pairs(defaults.highlights) do
          local color = "NONE"
          if name:find("error") or name:find("pick") then
            color = p.red
          elseif name:find("warning") or name:find("modified") then
            color = p.yellow
          elseif name:find("info") then
            color = p.blue
          elseif name:find("hint") then
            color = p.cyan
          elseif name:find("separator") or name == "fill" or name:find("duplicate") then
            color = p.bright_black
          end
          highlights[name] = {
            ctermfg = color,
            ctermbg = "NONE",
            bold = name:find("selected") ~= nil,
          }
        end
        return highlights
      end
    end,
  },
}
