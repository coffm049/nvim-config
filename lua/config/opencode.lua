-- Recommended setup (mirrors vim.pack example from https://github.com/nickjvandyke/opencode.nvim):
-- vim.pack.add({ { src = "https://github.com/nickjvandyke/opencode.nvim", version = vim.version.range("*") } })
-- is equivalent to the lazy.nvim spec in lua/plugins/opencode.lua:2.

-- Continue mode: when $OPENCODE_CONTINUE=1 in your terminal, start opencode with `-c`
-- (your snippet adapted to vim.g.opencode_opts API; `require("opencode").setup` does not exist)
local opencode_args = {}
if vim.env.OPENCODE_CONTINUE == "1" then
  table.insert(opencode_args, "-c")
end

---@type opencode.Opts
vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
  -- Your configuration, if any; goto definition on the type for details.
  -- Project-specific database isolation will be added when OPENCODE_HOME is supported.
  server = {
    -- Override start to include continue flag when requested
    start = function()
      local cmd = "opencode --port"
      if #opencode_args > 0 then
        cmd = cmd .. " " .. table.concat(opencode_args, " ")
      end
      vim.cmd("vsplit term://" .. cmd .. " | wincmd p")
    end,
  },
})