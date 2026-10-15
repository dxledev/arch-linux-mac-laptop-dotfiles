local M = {}

M.options = {
  build_directory = "build",
  configure_args = {},
  hide_build_directory_from_picker = true,
  parallel = 4,
}

function M.find_root(directory)
  if not directory or directory == "" then
    return
  end
  local root
  while directory do
    if vim.uv.fs_stat(vim.fs.joinpath(directory, "CMakeLists.txt")) then
      root = directory
    end
    if vim.uv.fs_stat(vim.fs.joinpath(directory, ".git")) then
      break
    end
    local parent = vim.fs.dirname(directory)
    directory = parent ~= directory and parent or nil
  end
  return root
end

function M.root(buffer)
  local path = vim.api.nvim_buf_get_name(buffer)
  local directory = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
  return M.find_root(directory)
end

function M.picker_excludes(directory)
  directory = directory or vim.uv.cwd()
  if not M.options.hide_build_directory_from_picker or M.find_root(directory) ~= directory then
    return {}
  end
  local build_directory = M.options.build_directory:gsub("^%./", ""):gsub("/+$", "")
  return { "**/" .. build_directory .. "/**" }
end

function M.build_directory(root)
  return vim.fs.abspath(vim.fs.joinpath(root, M.options.build_directory))
end

function M.root_dir(server, validate)
  return function(buffer, on_dir)
    local root = M.root(buffer)
    if root then
      local validation = require("config.cmake-validation")
      if validate and not validation.valid(root) then
        validation.check(root, function(valid, result)
          if not valid then
            vim.notify(result.stderr .. result.stdout, vim.log.levels.ERROR, { title = "CMake configuration failed" })
          end
          on_dir(root)
        end)
      else
        on_dir(root)
      end
    elseif type(server.root_dir) == "function" then
      server.root_dir(buffer, on_dir)
    else
      on_dir(server.root_dir or vim.fs.root(buffer, server.root_markers or { ".git" }))
    end
  end
end

function M.before_init(params, config)
  local root = config.root_dir
  if
    root
    and (
      vim.uv.fs_stat(vim.fs.joinpath(root, "CMakeLists.txt"))
      or vim.uv.fs_stat(M.build_directory(root) .. "/CMakeCache.txt")
    )
  then
    local validation = require("config.cmake-validation")
    config.init_options = config.init_options or {}
    config.init_options.compilationDatabasePath = validation.valid(root) and M.build_directory(root)
      or validation.empty_database()
    params.initializationOptions = config.init_options
  end
end

function M.configure_command(root)
  local command = { "cmake", "-S", root, "-B", M.build_directory(root) }
  vim.list_extend(command, M.options.configure_args)
  table.insert(command, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
  return command
end

function M.restart(root)
  for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    if client.config.root_dir == root and not client:is_stopped() then
      local buffers = vim.tbl_keys(client.attached_buffers)
      local config = vim.deepcopy(client.config)
      client:stop()
      vim.schedule(function()
        for _, buffer in ipairs(buffers) do
          if vim.api.nvim_buf_is_valid(buffer) and vim.api.nvim_buf_is_loaded(buffer) then
            vim.lsp.start(config, { bufnr = buffer })
          end
        end
      end)
    end
  end
end

local function run(command, root, environment)
  vim.system(
    command,
    { cwd = root, env = environment, text = true },
    vim.schedule_wrap(function(result)
      local output = (result.stdout or "") .. (result.stderr or "")
      if result.code ~= 0 then
        vim.notify(output, vim.log.levels.ERROR, { title = "CMake" })
        return
      end
      if output:find("Warning") or output:find("Error") then
        vim.notify(output, vim.log.levels.WARN, { title = "CMake" })
      end
      vim.notify("Build completed: " .. root, vim.log.levels.INFO, { title = "CMake" })
    end)
  )
end

function M.generate(build, dry_run)
  local root = M.root(0)
  if not root then
    vim.notify("No parent CMakeLists.txt found", vim.log.levels.ERROR)
    return
  end
  local directory = M.build_directory(root)
  local configure = M.configure_command(root)
  local compile = { "cmake", "--build", directory, "--parallel", tostring(M.options.parallel) }
  local headers = require("config.cpp-headers")
  if dry_run then
    local commands = { table.concat(vim.tbl_map(vim.fn.shellescape, configure), " ") }
    if build then
      local prefix = headers.options.enabled
          and ("env CPATH=" .. vim.fn.shellescape(headers.cpath(root, vim.env.CPATH)) .. " ")
        or ""
      table.insert(commands, prefix .. table.concat(vim.tbl_map(vim.fn.shellescape, compile), " "))
    end
    vim.notify(table.concat(commands, " &&\n"), vim.log.levels.INFO, { title = "CMake dry run" })
    return
  end
  vim.notify("Configuring: " .. root, vim.log.levels.INFO, { title = "CMake" })
  require("config.cmake-validation").check(root, function(valid, result)
    M.restart(root)
    if not valid then
      vim.notify(result.stderr .. result.stdout, vim.log.levels.ERROR, { title = "CMake configuration failed" })
      return
    end
    if build then
      run(compile, root, headers.environment(root))
    else
      vim.notify("Generated compiler settings: " .. directory, vim.log.levels.INFO, { title = "CMake" })
    end
  end)
end

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", M.options, options or {})
  vim.env.CMAKE_EXPORT_COMPILE_COMMANDS = "ON"
  vim.api.nvim_create_user_command("CMakeGenerate", function(args)
    M.generate(false, args.bang)
  end, { bang = true, desc = "Configure the root CMake project (! previews commands)" })
  vim.api.nvim_create_user_command("CMakeBuild", function(args)
    M.generate(true, args.bang)
  end, { bang = true, desc = "Configure and build the root CMake project (! previews commands)" })
  local group = vim.api.nvim_create_augroup("cmake_validation", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
    group = group,
    callback = function()
      local validation = require("config.cmake-validation")
      local roots = {}
      for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
        local root = client.config.root_dir
        if root and not client:is_stopped() and validation.changed(root) then
          roots[root] = true
        end
      end
      for root in pairs(roots) do
        validation.check(root, function(valid, result)
          if not valid then
            vim.notify(result.stderr .. result.stdout, vim.log.levels.ERROR, { title = "CMake configuration failed" })
          end
          M.restart(root)
        end)
      end
    end,
  })
end

return M
