local inlay_hint_config = {
  enabled_by_default = false,
  show_jsx_function_type_hints = false,
  show_struct_field_hints = false,
}

local inlay_hint_type_kind = 1

local function hint_label_text(label)
  if type(label) == "string" then
    return label
  end

  if type(label) ~= "table" then
    return ""
  end

  local parts = {}
  for _, part in ipairs(label) do
    parts[#parts + 1] = part.value or ""
  end

  return table.concat(parts)
end

local function is_array_index_hint(hint)
  local label = hint_label_text(hint.label)

  return label:match("^%s*/?%*?%s*%[%d+%]%s*[:=]?%s*%*?/?%s*$") ~= nil
end

local function is_struct_field_hint(hint)
  local label = hint_label_text(hint.label)

  return label:match("^%s*/?%*?%s*%.[_%a][_%w]*%s*[:=]?%s*%*?/?%s*$") ~= nil
end

local function lsp_character_to_byte(line, character, offset_encoding)
  if offset_encoding == "utf-8" then
    return character
  end

  return vim.str_byteindex(line, offset_encoding, character, false)
end

local function is_inside_formal_parameters(bufnr, position, offset_encoding)
  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1]
  if not line then
    return false
  end

  local byte_column = lsp_character_to_byte(line, position.character, offset_encoding)
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr,
    pos = { position.line, math.max(byte_column - 1, 0) },
  })

  if not ok then
    return false
  end

  while node do
    if node:type() == "formal_parameters" then
      return true
    end
    node = node:parent()
  end

  return false
end

local function is_jsx_function_type_hint(hint, ctx)
  if inlay_hint_config.show_jsx_function_type_hints or hint.kind ~= inlay_hint_type_kind then
    return false
  end

  local bufnr = ctx and ctx.bufnr
  if not bufnr or vim.bo[bufnr].filetype ~= "javascriptreact" then
    return false
  end

  local client = ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
  local offset_encoding = client and client.offset_encoding or "utf-16"

  return is_inside_formal_parameters(bufnr, hint.position, offset_encoding)
end

local function should_hide_hint(hint, ctx)
  if is_array_index_hint(hint) then
    return true
  end

  if not inlay_hint_config.show_struct_field_hints and is_struct_field_hint(hint) then
    return true
  end

  return is_jsx_function_type_hint(hint, ctx)
end

local function filter_inlay_hints(result, ctx)
  if type(result) ~= "table" then
    return result
  end

  return vim.tbl_filter(function(hint)
    return not should_hide_hint(hint, ctx)
  end, result)
end

local function setup_inlay_hint_filter()
  if vim.g.custom_inlay_hint_filter_loaded then
    return
  end

  vim.g.custom_inlay_hint_filter_loaded = true

  local default_handler = vim.lsp.handlers["textDocument/inlayHint"] or vim.lsp.inlay_hint.on_inlayhint

  vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
    return default_handler(err, filter_inlay_hints(result, ctx), ctx, config)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints.enabled = inlay_hint_config.enabled_by_default
      setup_inlay_hint_filter()
    end,
  },
}
