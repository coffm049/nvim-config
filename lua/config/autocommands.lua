-- Kept at file scope on purpose: requiring this registers the FileChangedShell
-- handler, which must exist before the first buffer is read or an early
-- conflict can be missed.
local sync = require 'misc.sync'
local workspace = require 'misc.workspace'

-- Pick up files changed outside of nvim (opencode writes straight to disk).
-- Needs 'autoread' (config/global.lua) to reload silently instead of prompting.
-- CursorHoldI is deliberately omitted: updatetime is 250ms, so it would reload
-- the buffer mid-keystroke.
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  pattern = { '*' },
  desc = 'Reload buffers changed outside nvim',
  callback = function()
    sync.recheck()
  end,
})

-- Global fallback: <Esc> exits terminal anywhere (even if TermOpen didn't fire yet)
-- Default nvim is <C-\><C-n>; we add <Esc> as convenience but keep original working
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true })
vim.keymap.set('t', '<C-[>', [[<C-\><C-n>]], { noremap = true, silent = true }) -- alias for Esc

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  group = vim.api.nvim_create_augroup("MyTerminalSettings", { clear = true }),
  pattern = { "*" },
  callback = function()
    local opts = { buffer = true, silent = true, noremap = true }

    -- Buffer-local <Esc> ensures exit even after global, and survives :terminal re-entry
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
    vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]], opts)

    vim.keymap.set("n", "H", ":tabprevious<CR>", opts)
    vim.keymap.set("n", "L", ":tabnext<CR>", opts)

    local buf = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(buf)
    if string.match(bufname, "opencode") then
      vim.b[buf].opencode = true
      vim.keymap.set("n", "<Esc>", "i<Esc>", opts)
      vim.keymap.set("t", "<C-Esc>", [[<C-\><C-n>]], opts)
      -- Removed: Shift-I (I) mapping that intercepted typing "I" in terminal mode
      -- vim.keymap.set("t", "I", [[<Esc>]], opts) was hijacking normal "I" input
      vim.schedule(function()
        workspace.name_terminal(buf, 'oc')
      end)
    end
  end,
})

-- Launch default terminal when nvim started with no file (nvim vs nvim file.txt)
-- Uses default shell (powershell on Windows per config/global.lua, bash/zsh on Unix)
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('AutoOpenTerminal', { clear = true }),
  callback = function()
    -- Only when no file arguments provided
    if vim.fn.argc() == 0 then
      local bufname = vim.api.nvim_buf_get_name(0)
      local line_count = vim.fn.line('$')
      local first_line = vim.fn.getline(1)
      -- Check for empty buffer (and not already a terminal / alpha edge case)
      local is_empty = bufname == '' and vim.bo.filetype == '' and line_count == 1 and first_line == ''
      -- Also allow alpha dashboard buffer (filetype 'alpha' or empty with dashboard)
      local is_alpha = vim.bo.filetype == 'alpha'
      if is_empty or is_alpha then
        -- Use schedule so TermOpen mappings are already defined and alpha is closed
        vim.schedule(function()
          -- Close alpha dashboard if present
          if vim.bo.filetype == 'alpha' then
            vim.cmd('bdelete')
          end
          -- Open terminal using default shell (powershell on Windows)
          vim.cmd('terminal')
          workspace.name_terminal_buffer(vim.api.nvim_get_current_buf())
          -- startinsert is optional; user can press i to enter. Keep it but now Esc/C-[ reliably exits
        end)
      end
    end
  end,
})

-- Name the initial tab (and its startup terminal, if any) after the cwd
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('WorkspaceTabName', { clear = true }),
  callback = function()
    vim.schedule(function()
      pcall(vim.cmd, 'redrawtabline')
      workspace.name_current_tab()
      workspace.name_terminal_buffer(vim.api.nvim_get_current_buf())
    end)
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
