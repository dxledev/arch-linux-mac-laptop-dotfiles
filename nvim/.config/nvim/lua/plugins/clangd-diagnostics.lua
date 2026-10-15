return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local clangd_tpp = require("config.clangd-tpp")
      clangd_tpp.setup()

      opts.servers = opts.servers or {}
      local clangd = opts.servers.clangd or {}
      local previous_before_init = clangd.before_init
      local previous_on_attach = clangd.on_attach

      opts.servers.clangd = vim.tbl_deep_extend("force", clangd, {
        filetypes = { "c", "c.doxygen", "cpp", "cpp.doxygen", "objc", "objcpp", "cuda", "cpp.tpp" },
        before_init = function(params, config)
          if previous_before_init then
            previous_before_init(params, config)
          end
          clangd_tpp.before_init(params, config)
        end,
        on_attach = function(client, buffer)
          if previous_on_attach then
            previous_on_attach(client, buffer)
          end
          clangd_tpp.on_attach(client, buffer)
        end,
        handlers = {
          ["textDocument/publishDiagnostics"] = function(...)
            return require("config.clangd-diagnostics").publish_diagnostics(...)
          end,
        },
      })
    end,
  },
}
