local M = {}

M.options = {
  enabled = true,
  max_depth = 16,
  extensions = { "h", "hpp", "hh", "hxx", "inc", "inl", "tpp" },
  exclude_directories = { "build", "CMakeFiles", "node_modules", "vendor", "target" },
}

function M.directories(root)
  local directories = { [root] = true }
  local extensions = {}
  for _, extension in ipairs(M.options.extensions) do
    extensions[extension] = true
  end
  for path, kind in
    vim.fs.dir(root, {
      depth = M.options.max_depth,
      skip = function(path)
        local name = vim.fs.basename(path)
        return not (
          name:sub(1, 1) == "."
          or name:match("^cmake%-build")
          or vim.tbl_contains(M.options.exclude_directories, name)
          or vim.uv.fs_stat(vim.fs.joinpath(root, path, "CMakeCache.txt"))
        )
      end,
    })
  do
    if kind == "file" and extensions[path:match("%.([^./]+)$")] then
      local directory = vim.fs.dirname(vim.fs.joinpath(root, path))
      while directory ~= root and not directories[directory] do
        directories[directory] = true
        directory = vim.fs.dirname(directory)
      end
    end
  end
  local result = vim.tbl_keys(directories)
  table.sort(result)
  return result
end

function M.cpath(root, inherited)
  local paths = M.directories(root)
  if inherited and inherited ~= "" then
    table.insert(paths, 1, inherited)
  end
  return table.concat(paths, ":")
end

function M.environment(root, environment)
  local result = vim.deepcopy(environment or {})
  if not M.options.enabled or not root or not require("config.cmake-validation").valid(root) then
    return result
  end
  result.CPATH = M.cpath(root, result.CPATH or vim.env.CPATH)
  return result
end

function M.command(command)
  return function(dispatchers, config)
    config._header_base_env = config._header_base_env or vim.deepcopy(config.cmd_env or {})
    config.cmd_env = M.environment(config.root_dir, config._header_base_env)
    if type(command) == "function" then
      return command(dispatchers, config)
    end
    return vim.lsp.rpc.start(command, dispatchers, {
      cwd = config.cmd_cwd,
      env = config.cmd_env,
      detached = config.detached,
    })
  end
end

return M
