-- Keep nvim buffers in sync with files changed outside of nvim (e.g. by
-- opencode, which writes straight to disk and never tells us about it).
--
-- Two halves:
--   recheck()        -- pick up external changes for buffers with no local edits
--   write_modified() -- flush local edits first, so recheck() is allowed to run
--
-- Relies on 'autoread' (set in config/global.lua): a buffer is only ever
-- reloaded when it has no unsaved changes of its own, which is why
-- write_modified() has to run *before* the agent touches the file.
--
-- The awkward case is a buffer with local edits whose file has *also* changed
-- on disk. Writing it would clobber the agent's change with stale local
-- content, so write_modified() refuses and reports instead. That detection is
-- delegated to neovim itself via FileChangedShell rather than reimplemented:
-- do not hand-roll mtime comparison, Windows defers timestamp updates and
-- will happily report an unchanged mtime for a file it just rewrote.

local M = {}

-- v:fcs_reason values that mean "disk content and buffer content disagree".
-- 'time' (timestamp only) and 'mode' are not content conflicts, and 'deleted'
-- is safe to write over, so none of those block a write.
local BLOCKING_REASONS = { conflict = true }

-- Guards against reloading out from under neovim. Terminal mode matters
-- because opencode runs in a :terminal split here. textlock covers the
-- expression-evaluation contexts that forbid changing buffer text (TextYankPost,
-- 'foldexpr', 'indentexpr', ...) -- a reload landing in one of those would
-- error or corrupt state. It is not set for ordinary Lua mappings.
local function reloading_is_safe()
  return vim.fn.mode() ~= 'c' and tonumber(vim.v.textlock or 0) == 0
end

---@return integer[] bufs buffers whose disk content conflicts with local edits
local function conflicted_bufs()
  local out = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].sync_conflict and vim.bo[buf].buflisted then
      table.insert(out, buf)
    end
  end
  return out
end

local function shortname(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
end

---Warn about conflicts, once per conflict, until the buffer is re-read/written.
local function report_conflicts(bufs)
  if #bufs == 0 then
    return
  end
  local fresh = vim.tbl_filter(function(buf)
    if vim.b[buf].sync_reported then
      return false
    end
    vim.b[buf].sync_reported = true
    return true
  end, bufs)
  if #fresh > 0 then
    vim.notify(
      string.format(
        'sync: %s changed on disk and also has unsaved local edits.\nRun :checktime to take the new version, or :w to overwrite it.',
        table.concat(vim.tbl_map(shortname, fresh), ', ')
      ),
      vim.log.levels.WARN
    )
  end
end

---Reload buffers whose file changed on disk since it was last read.
---No-op for modified buffers; those need write_modified() first.
function M.recheck()
  if not reloading_is_safe() then
    return
  end
  vim.cmd('checktime')
  report_conflicts(conflicted_bufs())
end

---Write every listed, modified, file-backed buffer that has no pending
---external change. Returns the names of the buffers that were skipped.
function M.write_modified()
  -- a conflict can appear at any time, so look before writing
  pcall(vim.cmd, 'checktime')

  local skipped = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bo = vim.bo[buf]
    if bo.buflisted and bo.modified and bo.buftype == '' and vim.api.nvim_buf_get_name(buf) ~= '' then
      if vim.b[buf].sync_conflict then
        table.insert(skipped, shortname(buf))
      else
        pcall(vim.api.nvim_buf_call, buf, function()
          vim.cmd('silent write')
        end)
      end
    end
  end
  report_conflicts(conflicted_bufs())
  return skipped
end

-- Neovim tells us, authoritatively, when a modified buffer's file changed
-- underneath it. Handling it here also suppresses the blocking W12 prompt
-- (see :help FileChangedShell) -- we report it as a notification instead.
-- Safe to do nothing else in this callback: current buffer is not the target
-- and switching/jumping/deleting buffers is not allowed here.
local group = vim.api.nvim_create_augroup('SyncWithDisk', { clear = true })

vim.api.nvim_create_autocmd('FileChangedShell', {
  group = group,
  pattern = { '*' },
  desc = 'Record external changes to modified buffers',
  callback = function(args)
    if BLOCKING_REASONS[vim.v.fcs_reason or ''] then
      vim.b[args.buf].sync_conflict = true
      vim.b[args.buf].sync_reported = false
    end
    vim.v.fcs_choice = '' -- handled here; suppress the W12 prompt
  end,
})

-- A conflict is resolved once the buffer has been re-read (reload, :e) or
-- written, because either way buffer and disk agree again.
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
  group = group,
  pattern = { '*' },
  desc = 'Clear conflict state once buffer matches disk',
  callback = function(args)
    vim.b[args.buf].sync_conflict = nil
    vim.b[args.buf].sync_reported = nil
  end,
})

return M
