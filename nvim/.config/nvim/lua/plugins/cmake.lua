return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      require("config.cmake").setup()
    end,
    opts = function(_, opts)
      local cmake = require("config.cmake")
      opts.servers = opts.servers or {}
      for _, name in ipairs({ "neocmake", "clangd" }) do
        local server = opts.servers[name] or {}
        local defaults = vim.lsp.config[name] or {}
        server.root_dir = cmake.root_dir({
          root_dir = server.root_dir or defaults.root_dir,
          root_markers = server.root_markers or defaults.root_markers,
        }, name == "clangd")
        opts.servers[name] = server
      end
      local clangd = opts.servers.clangd
      clangd.cmd = require("config.cpp-headers").command(clangd.cmd or vim.lsp.config.clangd.cmd)
      local before_init = clangd.before_init
      clangd.before_init = function(params, config)
        cmake.before_init(params, config)
        if before_init then
          before_init(params, config)
        end
      end
    end,
  },
}
