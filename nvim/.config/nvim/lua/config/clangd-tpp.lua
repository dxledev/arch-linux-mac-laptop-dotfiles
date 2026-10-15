local tpp_context_config = {
  compiler = "/usr/bin/clang++",
  compile_flags_file = "compile_flags.txt",
  fallback_flags = { "-std=c++23" },
  header_extensions = { "h", "hpp", "hh", "hxx" },
  max_files_per_root = 1000,
  change_debounce_ms = 150,
}

local M = { config = tpp_context_config }
local contexts = {}
local change_generations = {}

local function normalize(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function matching_header(tpp_file)
  local base = tpp_file:sub(1, -5)
  for _, extension in ipairs(tpp_context_config.header_extensions) do
    local header = base .. "." .. extension
    if vim.uv.fs_stat(header) then
      return header
    end
  end
end

local function compile_flags(tpp_file, root)
  local flags_file = vim.fs.find(tpp_context_config.compile_flags_file, {
    path = vim.fs.dirname(tpp_file),
    upward = true,
    stop = vim.fs.dirname(root),
    type = "file",
  })[1]

  if not flags_file then
    return vim.deepcopy(tpp_context_config.fallback_flags)
  end

  local flags = {}
  for _, line in ipairs(vim.fn.readfile(flags_file)) do
    local flag = vim.trim(line)
    if flag ~= "" then
      table.insert(flags, flag)
    end
  end
  return flags
end

local function shadow_directory(root)
  return vim.fs.joinpath(vim.fn.stdpath("cache"), "clangd-tpp", vim.fn.sha256(root):sub(1, 12))
end

local function shadow_header_path(root, tpp_file, header)
  local name = vim.fn.sha256(tpp_file):sub(1, 12) .. "-" .. vim.fs.basename(header)
  return vim.fs.joinpath(shadow_directory(root), name)
end

local function without_tpp_include(lines, tpp_name)
  local filtered = {}
  for index, line in ipairs(lines) do
    local compact = line:gsub("%s", "")
    local included_file = compact:match('^#include["<]([^">]+)[">]')
    if included_file == tpp_name then
      filtered[index] = ""
    else
      filtered[index] = line
    end
  end
  return filtered
end

local function header_lines(header)
  local buffer = vim.fn.bufnr(header)
  if buffer ~= -1 and vim.api.nvim_buf_is_loaded(buffer) then
    return vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  end
  return vim.fn.readfile(header)
end

local function write_shadow(context)
  vim.fn.mkdir(vim.fs.dirname(context.shadow_header), "p")
  local lines = without_tpp_include(header_lines(context.header), vim.fs.basename(context.tpp_file))
  vim.fn.writefile(lines, context.shadow_header)
end

local function compilation_command(context, root)
  local command = { tpp_context_config.compiler }
  vim.list_extend(command, compile_flags(context.tpp_file, root))
  vim.list_extend(command, {
    "-DNVIM_TPP_CONTEXT_REVISION=" .. context.revision,
    "-iquote",
    vim.fs.dirname(context.header),
    "-include",
    context.shadow_header,
    "-x",
    "c++",
    context.tpp_file,
  })

  return {
    workingDirectory = vim.fs.dirname(context.tpp_file),
    compilationCommand = command,
  }
end

local function prepare_context(root, tpp_file)
  tpp_file = normalize(tpp_file)
  local header = matching_header(tpp_file)
  if not header then
    return
  end

  local context = {
    header = normalize(header),
    revision = 1,
    root = root,
    shadow_header = shadow_header_path(root, tpp_file, header),
    tpp_file = tpp_file,
  }
  write_shadow(context)
  context.command = compilation_command(context, root)
  contexts[tpp_file] = context
  return context
end

local function compilation_changes(root)
  local changes = {}
  for _, context in pairs(contexts) do
    if context.root == root then
      changes[context.tpp_file] = context.command
    end
  end
  return changes
end

local function root_from_config(params, config)
  if config.root_dir then
    return normalize(config.root_dir)
  end
  if params.rootUri then
    return normalize(vim.uri_to_fname(params.rootUri))
  end
end

local function tpp_files(root)
  return vim.fs.find(function(name)
    return name:sub(-4) == ".tpp"
  end, {
    path = root,
    type = "file",
    limit = tpp_context_config.max_files_per_root,
  })
end

local function client_root(client)
  local root = client.config and client.config.root_dir
  return root and normalize(root) or nil
end

local function notify_compilation_changes(client, root)
  client:notify("workspace/didChangeConfiguration", {
    settings = {
      compilationDatabaseChanges = compilation_changes(root),
    },
  })
end

local function notify_shadow_changed(context)
  for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    if client_root(client) == context.root then
      notify_compilation_changes(client, context.root)
      client:notify("workspace/didChangeWatchedFiles", {
        changes = {
          { uri = vim.uri_from_fname(context.shadow_header), type = 2 },
        },
      })
    end
  end
end

local function refresh_header(header)
  header = normalize(header)
  for _, context in pairs(contexts) do
    if context.header == header then
      write_shadow(context)
      context.revision = context.revision + 1
      context.command = compilation_command(context, context.root)
      notify_shadow_changed(context)
    end
  end
end

local function refresh_header_after_change(buffer)
  change_generations[buffer] = (change_generations[buffer] or 0) + 1
  local generation = change_generations[buffer]

  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buffer) or change_generations[buffer] ~= generation then
      return
    end
    refresh_header(vim.api.nvim_buf_get_name(buffer))
  end, tpp_context_config.change_debounce_ms)
end

function M.before_init(params, config)
  local root = root_from_config(params, config)
  if not root then
    return
  end

  local changes = vim.deepcopy((config.init_options or {}).compilationDatabaseChanges or {})
  for _, tpp_file in ipairs(tpp_files(root)) do
    local context = prepare_context(root, tpp_file)
    if context then
      changes[context.tpp_file] = context.command
    end
  end

  config.init_options = config.init_options or {}
  config.init_options.compilationDatabaseChanges = changes
end

function M.on_attach(client, buffer)
  if vim.bo[buffer].filetype ~= "cpp.tpp" then
    return
  end

  local root = client_root(client)
  local tpp_file = normalize(vim.api.nvim_buf_get_name(buffer))
  local context = contexts[tpp_file] or (root and prepare_context(root, tpp_file))
  if not context then
    vim.lsp.buf_detach_client(buffer, client.id)
    return
  end

  notify_compilation_changes(client, root)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("clangd_tpp_context", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
    group = group,
    pattern = { "*.h", "*.hpp", "*.hh", "*.hxx" },
    callback = function(event)
      refresh_header_after_change(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    pattern = { "*.h", "*.hpp", "*.hh", "*.hxx" },
    callback = function(event)
      change_generations[event.buf] = nil
    end,
  })
end

return M
