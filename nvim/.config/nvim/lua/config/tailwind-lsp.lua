local M = {}

M.config = {
  entrypoint_candidates = {
    "src/index.css",
    "src/main.css",
    "src/app.css",
    "src/styles.css",
  },
}

local function has_tailwind_import(path)
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    if require("config.tailwind-css").config.import_lines[vim.trim(line)] then
      return true
    end
  end

  return false
end

local function find_entrypoint(root_dir)
  for _, relative_path in ipairs(M.config.entrypoint_candidates) do
    if has_tailwind_import(vim.fs.joinpath(root_dir, relative_path)) then
      return relative_path
    end
  end
end

function M.before_init(_, config)
  config.settings = vim.tbl_deep_extend("keep", config.settings or {}, {
    editor = {
      tabSize = vim.lsp.util.get_effective_tabstop(),
    },
  })

  local tailwind_settings = config.settings and config.settings.tailwindCSS or {}
  local experimental = tailwind_settings.experimental or {}

  if experimental.configFile or not config.root_dir then
    return
  end

  local entrypoint = find_entrypoint(config.root_dir)
  if not entrypoint then
    return
  end

  config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
    tailwindCSS = {
      experimental = {
        configFile = entrypoint,
      },
    },
  })
end

return M
