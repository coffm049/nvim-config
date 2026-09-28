return {
  {
    'nickjvandyke/opencode.nvim',
    version = '*',
    dependencies = {
      -- Recommended for enhanced `ask` (input) and `select` (picker) UX,
      -- but not strictly required. Uncomment if you use snacks.nvim.
      -- 'folke/snacks.nvim',
      'nvim-lua/plenary.nvim',
    },
    config = function()
      -- Mirrors recommended vim.pack setup:
      -- vim.g.opencode_opts = { -- Your configuration -- }
      -- (also set early in lua/config/opencode.lua:4)
      ---@type opencode.Opts
      vim.g.opencode_opts = vim.g.opencode_opts or {}

      -- Recommended keymaps (from https://github.com/nickjvandyke/opencode.nvim#setup)
      -- Adjust or remove any that conflict with your existing mappings.
      --
      -- ask/select hand real work to the agent, so flush local edits first:
      -- 'autoread' can only reload a buffer that has no unsaved changes, and
      -- the agent is about to edit files on disk. The `command`/`operator`
      -- mappings are left alone: scrolling and building insert text are not
      -- edit delegations (and expr mappings must stay side-effect free).
      local sync = require 'misc.sync'
      local function delegating(fn)
        return function(...)
          sync.write_modified()
          return fn(...)
        end
      end

      vim.keymap.set({ 'n', 'x' }, '<C-a>', delegating(function() require('opencode').ask('@this: ') end), { desc = 'Ask OpenCode…' })
      vim.keymap.set({ 'n', 'x' }, '<C-x>', delegating(function() require('opencode').select() end), { desc = 'Select OpenCode…' })
      vim.keymap.set({ 'n', 'x' }, 'go', function() return require('opencode').operator('@this ') end, { desc = 'Append range to OpenCode', expr = true })
      vim.keymap.set('n', 'goo', function() return require('opencode').operator('@this ') .. '_' end, { desc = 'Append line to OpenCode', expr = true })
      vim.keymap.set('n', '<S-C-u>', function() require('opencode').command('session.half.page.up') end, { desc = 'Scroll OpenCode up' })
      vim.keymap.set('n', '<S-C-d>', function() require('opencode').command('session.half.page.down') end, { desc = 'Scroll OpenCode down' })

      -- Optional: which-key group (requires which-key, already in this config via ui.lua)
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { '<leader>a', group = '[a]i / opencode' },
          { '<leader>ao', desc = 'Open OpenCode terminal (legacy)' },
        })
      end
    end,
  },
}
