-- Only cterm colors: the terminal owns all RGB values and the default background.
vim.opt.termguicolors = false
vim.cmd.highlight("clear")
vim.g.colors_name = "terminal-ansi"

-- Remove Neovim's built-in RGB/256-color definitions, keeping its default links.
for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
  if not hl.link then
    vim.api.nvim_set_hl(0, name, {})
  end
end

local p = require("config.palette")
local function hi(name, fg, bg, style)
  local hl = vim.tbl_extend("force", {}, style or {})
  hl.ctermfg = fg
  hl.ctermbg = bg
  vim.api.nvim_set_hl(0, name, hl)
end
local function link(name, target)
  vim.api.nvim_set_hl(0, name, { link = target })
end

hi("Normal")
hi("Comment", p.bright_black, nil, { italic = true })
hi("Constant", p.yellow)
hi("String", p.green)
hi("Character", p.green)
hi("Number", p.yellow)
hi("Boolean", p.yellow)
hi("Float", p.yellow)
hi("Identifier", p.cyan)
hi("Function", p.blue)
hi("Statement", p.magenta)
hi("Operator", p.cyan)
hi("PreProc", p.yellow)
hi("Type", p.cyan)
hi("Special", p.bright_magenta)
hi("Delimiter", p.bright_black)
hi("Underlined", p.blue, nil, { underline = true })
hi("Ignore", p.bright_black)
hi("Error", p.red, nil, { bold = true })
hi("Todo", p.yellow, nil, { bold = true })
hi("Added", p.green)
hi("Changed", p.yellow)
hi("Removed", p.red)
hi("Debug", p.yellow)

hi("NonText", p.bright_black)
hi("Whitespace", p.bright_black)
hi("EndOfBuffer", p.bright_black)
hi("LineNr", p.bright_black)
hi("CursorLineNr", p.yellow, nil, { bold = true })
hi("CursorLine", nil, nil, { underline = true })
hi("CursorColumn", nil, nil, { reverse = true })
hi("ColorColumn", nil, nil, { reverse = true })
hi("Cursor", nil, nil, { reverse = true })
hi("TermCursor", nil, nil, { reverse = true })
hi("Visual", nil, nil, { reverse = true })
hi("Search", p.black, p.yellow)
hi("IncSearch", p.black, p.bright_yellow, { bold = true })
hi("MatchParen", p.bright_cyan, nil, { bold = true, underline = true })
hi("Directory", p.blue, nil, { bold = true })
hi("Title", p.magenta, nil, { bold = true })
hi("WinSeparator", p.bright_black)
hi("FloatBorder", p.bright_black)
hi("FloatTitle", p.blue, nil, { bold = true })
hi("Folded", p.bright_black)
hi("FoldColumn", p.bright_black)
hi("StatusLine", nil, nil, { reverse = true })
hi("StatusLineNC", p.bright_black, nil, { reverse = true })
hi("TabLine", p.bright_black)
hi("TabLineSel", p.blue, nil, { bold = true, underline = true })
hi("PmenuSel", nil, nil, { reverse = true, bold = true })
hi("PmenuThumb", nil, nil, { reverse = true })
hi("Question", p.green)
hi("MoreMsg", p.green)
hi("ModeMsg", p.green, nil, { bold = true })
hi("WarningMsg", p.yellow)
hi("ErrorMsg", p.red)
hi("DiffAdd", p.green)
hi("DiffChange", p.yellow)
hi("DiffDelete", p.red)
hi("DiffText", p.yellow, nil, { reverse = true })
hi("LspInlayHint", p.bright_black, nil, { italic = true })
hi("LspReferenceText", nil, nil, { underline = true })
hi("LspSignatureActiveParameter", p.cyan, nil, { bold = true })

for _, name in ipairs({ "NormalNC", "NormalFloat", "SignColumn", "CursorLineSign", "TabLineFill", "Pmenu", "PmenuSbar" }) do
  link(name, "Normal")
end
for name, target in pairs({
  Conditional = "Statement", Repeat = "Statement", Label = "Statement", Keyword = "Statement",
  Exception = "Statement", Include = "PreProc", Define = "PreProc", Macro = "PreProc", PreCondit = "PreProc",
  StorageClass = "Type", Structure = "Type", Typedef = "Type", Tag = "Special", SpecialChar = "Special",
  SpecialComment = "Comment", SpecialKey = "NonText", Conceal = "Comment", VertSplit = "WinSeparator",
  QuickFixLine = "PmenuSel", WildMenu = "PmenuSel", CurSearch = "IncSearch", Substitute = "IncSearch",
  VisualNOS = "Visual", CursorIM = "Cursor", lCursor = "Cursor", TermCursorNC = "Cursor",
  CursorLineFold = "FoldColumn", MsgArea = "Normal", MsgSeparator = "WinSeparator", OkMsg = "MoreMsg",
  PmenuKind = "Type", PmenuExtra = "Comment", PmenuKindSel = "PmenuSel", PmenuExtraSel = "PmenuSel",
  PmenuMatch = "Special", PmenuMatchSel = "PmenuSel", WinBar = "Normal", WinBarNC = "Comment",
  LspReferenceRead = "LspReferenceText", LspReferenceWrite = "LspReferenceText", LspReferenceTarget = "LspReferenceText",
  SnippetTabstop = "Visual", DapStoppedLine = "Visual", DapBreakpoint = "DiagnosticError",
  healthError = "ErrorMsg", healthWarning = "WarningMsg", healthSuccess = "MoreMsg",
}) do
  link(name, target)
end

for severity, color in pairs({ Error = p.red, Warn = p.yellow, Info = p.blue, Hint = p.cyan, Ok = p.green }) do
  local base = "Diagnostic" .. severity
  hi(base, color)
  for _, kind in ipairs({ "Sign", "Floating", "VirtualText", "VirtualLines" }) do
    link("Diagnostic" .. kind .. severity, base)
  end
  hi("DiagnosticUnderline" .. severity, color, nil, { underline = true })
end
hi("DiagnosticDeprecated", nil, nil, { strikethrough = true })
link("DiagnosticUnnecessary", "Comment")
for name, target in pairs({ SpellBad = "DiagnosticError", SpellCap = "DiagnosticWarn", SpellLocal = "DiagnosticHint", SpellRare = "DiagnosticInfo" }) do
  local color = vim.api.nvim_get_hl(0, { name = target, link = false }).ctermfg
  hi(name, color, nil, { underline = true })
end

-- Treesitter and LSP tokens, including the custom C++ query captures.
for name, target in pairs({
  ["@variable"] = "Normal", ["@variable.builtin"] = "Special", ["@variable.parameter"] = "Identifier",
  ["@variable.member"] = "Identifier", ["@constant"] = "Constant", ["@constant.builtin"] = "Special",
  ["@module"] = "Type", ["@namespace.definition"] = "Type", ["@label"] = "Label",
  ["@string"] = "String", ["@string.escape"] = "SpecialChar", ["@string.regexp"] = "Special",
  ["@character"] = "Character", ["@number"] = "Number", ["@boolean"] = "Boolean", ["@type"] = "Type",
  ["@attribute"] = "PreProc", ["@property"] = "Identifier", ["@function"] = "Function",
  ["@function.builtin"] = "Special", ["@constructor"] = "Function", ["@operator"] = "Operator",
  ["@keyword"] = "Keyword", ["@keyword.return"] = "Statement", ["@keyword.operator"] = "Operator",
  ["@punctuation"] = "Delimiter", ["@punctuation.special"] = "Special", ["@comment"] = "Comment",
  ["@comment.documentation.return"] = "String", ["@comment.todo"] = "Todo", ["@comment.error"] = "Error",
  ["@tag"] = "Tag", ["@tag.attribute"] = "Identifier", ["@tag.delimiter"] = "Delimiter",
  ["@markup.heading"] = "Title", ["@markup.link"] = "Underlined", ["@markup.raw"] = "String",
  ["@markup.list"] = "Special", ["@markup.quote"] = "Comment", ["@markup.math"] = "Special",
  ["@lsp.type.namespace"] = "Type", ["@lsp.type.class"] = "Type", ["@lsp.type.struct"] = "Type",
  ["@lsp.type.enum"] = "Type", ["@lsp.type.interface"] = "Type", ["@lsp.type.typeParameter"] = "Type",
  ["@lsp.type.function"] = "Function", ["@lsp.type.method"] = "Function", ["@lsp.type.variable"] = "@variable",
  ["@lsp.type.parameter"] = "Identifier", ["@lsp.type.property"] = "Identifier", ["@lsp.type.enumMember"] = "Constant",
  ["@lsp.type.macro"] = "Macro", ["@lsp.type.comment"] = "Comment", ["@lsp.type.keyword"] = "Keyword",
}) do
  link(name, target)
end
hi("@markup.strong", nil, nil, { bold = true })
hi("@markup.italic", nil, nil, { italic = true })
hi("@markup.strikethrough", nil, nil, { strikethrough = true })

-- Predefine plugin groups so their default highlights inherit the same palette.
for name, target in pairs({
  GitSignsAdd = "Added", GitSignsChange = "Changed", GitSignsDelete = "Removed",
  GitSignsTopdelete = "Removed", GitSignsChangedelete = "Changed", GitSignsUntracked = "Added",
  BlinkCmpMenu = "Pmenu", BlinkCmpMenuBorder = "FloatBorder", BlinkCmpMenuSelection = "PmenuSel",
  BlinkCmpLabel = "Normal", BlinkCmpLabelMatch = "Special", BlinkCmpLabelDetail = "Comment",
  BlinkCmpLabelDescription = "Comment", BlinkCmpSource = "Comment", BlinkCmpKind = "Type",
  BlinkCmpDoc = "NormalFloat", BlinkCmpDocBorder = "FloatBorder", BlinkCmpDocSeparator = "FloatBorder",
  BlinkCmpSignatureHelp = "NormalFloat", BlinkCmpSignatureHelpBorder = "FloatBorder",
  BlinkCmpSignatureHelpActiveParameter = "LspSignatureActiveParameter",
  BlinkCmpScrollBarGutter = "PmenuSbar", BlinkCmpScrollBarThumb = "PmenuThumb",
  SnacksNormal = "NormalFloat", SnacksBackdrop = "Normal", SnacksWinBar = "Normal",
  SnacksPickerNormal = "NormalFloat", SnacksPickerBorder = "FloatBorder", SnacksPickerTitle = "FloatTitle",
  SnacksPickerMatch = "Special", SnacksPickerSelected = "Special", SnacksPickerCursorLine = "PmenuSel",
  SnacksPickerDir = "Comment", SnacksPickerDirectory = "Directory", SnacksPickerFile = "Normal",
  SnacksPickerPrompt = "Special", SnacksPickerInput = "NormalFloat", SnacksPickerList = "NormalFloat",
  SnacksPickerPreview = "NormalFloat", SnacksPickerInputBorder = "FloatBorder", SnacksPickerListBorder = "FloatBorder",
  SnacksPickerPreviewBorder = "FloatBorder", SnacksIndent = "NonText", SnacksIndentScope = "Comment",
  SnacksDashboardHeader = "Title", SnacksDashboardIcon = "Special", SnacksDashboardDesc = "Normal",
  SnacksDashboardKey = "Special", SnacksDashboardSpecial = "Special", SnacksDashboardFooter = "Comment",
  SnacksDashboardDir = "Comment", SnacksNotifierBorderInfo = "DiagnosticInfo",
  SnacksNotifierBorderWarn = "DiagnosticWarn", SnacksNotifierBorderError = "DiagnosticError",
  WhichKeyNormal = "NormalFloat", WhichKeyBorder = "FloatBorder", WhichKey = "Special",
  WhichKeyGroup = "Title", WhichKeyDesc = "Normal", WhichKeySeparator = "Comment", WhichKeyValue = "Comment",
  NoiceCmdlinePopup = "NormalFloat", NoiceCmdlinePopupBorder = "FloatBorder", NoiceCmdlineIcon = "Special",
  NoicePopupmenu = "Pmenu", NoicePopupmenuSelected = "PmenuSel", NoicePopupmenuBorder = "FloatBorder",
  LazyNormal = "NormalFloat", LazyBorder = "FloatBorder", MasonNormal = "NormalFloat",
  TroubleNormal = "Normal", TroubleNormalNC = "NormalNC", TroubleIndent = "NonText",
  NeoTreeNormal = "Normal", NeoTreeNormalNC = "NormalNC", NeoTreeEndOfBuffer = "EndOfBuffer",
  NeoTreeWinSeparator = "WinSeparator", NeoTreeDirectoryIcon = "Directory", NeoTreeDirectoryName = "Directory",
  MiniIconsAzure = "Function", MiniIconsBlue = "Function", MiniIconsCyan = "Type", MiniIconsGreen = "String",
  MiniIconsGrey = "Comment", MiniIconsOrange = "Constant", MiniIconsPurple = "Statement",
  MiniIconsRed = "Error", MiniIconsYellow = "Constant",
}) do
  link(name, target)
end
