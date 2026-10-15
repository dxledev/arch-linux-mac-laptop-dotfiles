local M = {}
local projects = {}

local function inputs(root)
  if not root or vim.fn.filereadable(root .. "/CMakeLists.txt") ~= 1 then
    return nil
  end
  local files = {}
  for path, kind in
    vim.fs.dir(root, {
      depth = 32,
      skip = function(path)
        local name = vim.fs.basename(path)
        return name ~= ".git"
          and name ~= "node_modules"
          and not vim.uv.fs_stat(root .. "/" .. path .. "/CMakeCache.txt")
      end,
    })
  do
    if
      kind == "file"
      and (vim.fs.basename(path) == "CMakeLists.txt" or path:match("%.cmake$") or path:match("CMake.*Presets%.json$"))
    then
      table.insert(files, path .. "\n" .. table.concat(vim.fn.readfile(root .. "/" .. path), "\n"))
    end
  end
  table.sort(files)
  return vim.fn.sha256(table.concat(files, "\n"))
end

local function database(root)
  local directory = require("config.cmake").build_directory(root)
  local path = directory .. "/compile_commands.json"
  if vim.fn.filereadable(path) ~= 1 or vim.fn.filereadable(directory .. "/CMakeCache.txt") ~= 1 then
    return nil
  end
  local content = table.concat(vim.fn.readfile(path), "\n")
  local ok, commands = pcall(vim.json.decode, content)
  if not ok or type(commands) ~= "table" or not vim.islist(commands) then
    return nil
  end
  local cache = table.concat(vim.fn.readfile(directory .. "/CMakeCache.txt"), "\n")
  return vim.fn.sha256(content .. cache .. table.concat(require("config.cmake").configure_command(root), "\n"))
end

function M.valid(root)
  local project = root and projects[root]
  return project ~= nil and project.valid and project.inputs == inputs(root) and project.database == database(root)
end

function M.empty_database()
  local directory = vim.fn.stdpath("cache") .. "/cmake-unconfigured"
  vim.fn.mkdir(directory, "p")
  return directory
end

function M.check(root, callback)
  local previous = projects[root]
  if previous and previous.callbacks then
    table.insert(previous.callbacks, callback)
    return
  end
  local project = { inputs = inputs(root), valid = false, callbacks = { callback } }
  projects[root] = project
  local function finish(result)
    project.database = database(root)
    project.valid = result.code == 0
      and project.inputs ~= nil
      and project.inputs == inputs(root)
      and project.database ~= nil
    if result.code == 0 and not project.valid then
      result.stderr = (result.stderr or "") .. "\nCMake inputs changed or no valid compilation database was generated."
    end
    local callbacks = project.callbacks
    project.callbacks = nil
    for _, done in ipairs(callbacks) do
      done(project.valid, result)
    end
  end
  if not project.inputs then
    finish({ code = 1, stdout = "", stderr = "No CMakeLists.txt found in " .. root })
    return
  end
  local ok, error_message = pcall(
    vim.system,
    require("config.cmake").configure_command(root),
    { cwd = root, text = true },
    vim.schedule_wrap(finish)
  )
  if not ok then
    finish({ code = 1, stdout = "", stderr = tostring(error_message) })
  end
end

function M.changed(root)
  local project = projects[root]
  return project and not project.callbacks and (project.inputs ~= inputs(root) or project.database ~= database(root))
end

return M
