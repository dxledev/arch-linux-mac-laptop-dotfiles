 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a110e',
    base01 = '#271e1a',
    base02 = '#322824',
    base03 = '#a08d86',
    base04 = '#d8c2bb',
    base05 = '#f1dfd9',
    base06 = '#f1dfd9',
    base07 = '#f1dfd9',
    base08 = '#ffb4ab',
    base09 = '#d4c78e',
    base0A = '#e7beaf',
    base0B = '#ffb59a',
    base0C = '#d4c78e',
    base0D = '#ffb59a',
    base0E = '#e7beaf',
    base0F = '#ffdbce',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f1dfd9',          bg = '#1a110e' })
  hi('TelescopeBorder',         { fg = '#a08d86',             bg = '#1a110e' })
  hi('TelescopePromptNormal',   { fg = '#f1dfd9',          bg = '#1a110e' })
  hi('TelescopePromptBorder',   { fg = '#a08d86',             bg = '#1a110e' })
  hi('TelescopePromptPrefix',   { fg = '#ffb59a',             bg = '#1a110e' })
  hi('TelescopePromptCounter',  { fg = '#d8c2bb',  bg = '#1a110e' })
  hi('TelescopePromptTitle',    { fg = '#1a110e',             bg = '#ffb59a' })
  hi('TelescopePreviewTitle',   { fg = '#1a110e',             bg = '#e7beaf' })
  hi('TelescopeResultsTitle',   { fg = '#1a110e',             bg = '#d4c78e' })
  hi('TelescopeSelection',      { fg = '#f1dfd9',          bg = '#322824' })
  hi('TelescopeSelectionCaret', { fg = '#ffb59a',             bg = '#322824' })
  hi('TelescopeMatching',       { fg = '#ffb59a',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#f1dfd9',          bg = '#1a110e' })
  hi('MiniPickBorder',         { fg = '#a08d86',             bg = '#1a110e' })
  hi('MiniPickPrompt',   { fg = '#f1dfd9',          bg = '#1a110e' })
  hi('MiniPickPromptPrefix',   { fg = '#ffb59a',             bg = '#1a110e' })
  hi('MiniPickBorderText',    { fg = '#1a110e',             bg = '#ffb59a' })
  hi('MiniPickMatchCurrent',      { fg = '#f1dfd9',          bg = '#322824' })
  hi('MiniPickPromptCaret', { fg = '#ffb59a',             bg = '#322824' })
  hi('MiniPickMatchRanges',       { fg = '#ffb59a',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
