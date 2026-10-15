local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

ls.config.set_config({
  enable_autosnippets = true,
})

local function guard_name(_, snip)
  return snip.captures[1]
end

-- Export Default
local expd = s(
  {
    trig = "([%w_]+)%s+expd",
    regTrig = true,
    wordTrig = false,
    snippetType = "autosnippet",
    name = "export default",
  },
  {
    t({
      "import '';",
      "",
      "function ",
    }),
    f(guard_name),

    t({ "() {", "" }),
    t({ "  return ("}),
    t({ "", "" }),
    t({ "    <>", "    " }),
    i(1),
    t({ "", "" }),
    t({ "    </>", "" }),
    t({ "  );", "" }),
    t({ "}", "" }),
    t({ "", "" }),
    t({ "export default " }), f(guard_name), t({ ";", "" }),
  }
)

for _, ft in ipairs({ "typescriptreact", "javascriptreact" }) do
  ls.add_snippets(ft, {
    expd,
  })
end
