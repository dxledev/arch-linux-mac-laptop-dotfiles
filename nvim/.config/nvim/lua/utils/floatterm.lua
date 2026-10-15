local M = {}

local term_win, term_buf = nil, nil
local orig_cwd = nil

function M.toggle(opts)
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
    term_win = nil

    -- restore original cwd
    if orig_cwd then
      vim.loop.chdir(orig_cwd)
      orig_cwd = nil
    end
    return
  end

  opts = opts or {}
  local ui = vim.api.nvim_list_uis()[1]
  local width  = math.floor((opts.width  or 0.8) * ui.width)
  local height = math.floor((opts.height or 0.8) * ui.height)
  local col = math.floor((ui.width  - width)  / 2)
  local row = math.floor((ui.height - height) / 2)

  -- get the absolute directory of the current file
  local file_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  if file_dir == "" then
    file_dir = vim.fn.getcwd()
  end

  -- save original working directory and temporarily switch process dir
  orig_cwd = vim.loop.cwd()
  vim.loop.chdir(file_dir)

  -- save all files before opening floatterm
  vim.cmd("silent! wa")

  -- create window + terminal
  term_buf = vim.api.nvim_create_buf(false, true)
  term_win = vim.api.nvim_open_win(term_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_set_option_value(
    "winhighlight",
    "Normal:NormalFloat,NormalNC:NormalFloat",
    { win = term_win }
  )

  -- NOW it will inherit the correct directory
  local cmd = string.format('cd "%s" && exec bash -i', file_dir)
  vim.fn.termopen({"bash", "-c", cmd})
  vim.cmd("startinsert")

  -- close key
  vim.keymap.set({"t", "n"}, "<Esc>", function()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
      vim.api.nvim_win_close(term_win, true)
      term_win = nil

      -- restore Neovim's original cwd
      if orig_cwd then
        vim.loop.chdir(orig_cwd)
        orig_cwd = nil
      end
    end
  end, { buffer = term_buf })
end

return M
