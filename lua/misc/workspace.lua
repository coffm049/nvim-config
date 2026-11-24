local M = {}

local function tab_name_module()
  local ok, mod = pcall(require, 'tabby.feature.tab_name')
  return ok and mod or nil
end

function M.set_tab_name(name)
  if not name or name == '' then
    return
  end
  local mod = tab_name_module()
  if mod then
    mod.set(0, name)
  end
  vim.t.tab_name = name
end

function M.cwd_name()
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ':t')
  return name ~= '' and name or cwd
end

function M.tab_name()
  local mod = tab_name_module()
  if mod then
    local name = mod.get_raw(0)
    if name ~= '' then
      return name
    end
  end
  if vim.t.tab_name and vim.t.tab_name ~= '' then
    return vim.t.tab_name
  end
  return M.cwd_name()
end

function M.name_current_tab(name)
  local mod = tab_name_module()
  local existing = mod and mod.get_raw(0) or ''
  if existing ~= '' or (vim.t.tab_name and vim.t.tab_name ~= '') then
    return
  end
  M.set_tab_name(name or M.cwd_name())
end

function M.name_terminal_buffer(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  if vim.bo[buf].buftype ~= 'terminal' then
    return
  end
  local current = vim.api.nvim_buf_get_name(buf)
  if current ~= '' and not current:match('^term://') then
    return
  end
  M.set_buf_name(buf, M.tab_name())
end

function M.set_buf_name(buf, name)
  if not (buf and name and name ~= '' and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  pcall(vim.api.nvim_buf_set_name, buf, name)
end

function M.name_terminal(buf, suffix)
  local mod = tab_name_module()
  local base = mod and mod.get_raw(0) or ''
  if base == '' and vim.t.tab_name then
    base = vim.t.tab_name
  end
  local name = base
  if suffix then
    name = base ~= '' and (base .. '_' .. suffix) or ('_' .. suffix)
  end
  M.set_buf_name(buf, name)
end

function M.new_workspace(dir)
  dir = vim.fn.fnamemodify(vim.fn.expand(dir ~= '' and dir or vim.fn.getcwd()), ':p')
  dir = dir:gsub('[/\\]+$', '')
  local name = vim.fn.fnamemodify(dir, ':t')
  if name == '' then
    name = dir
  end

  vim.cmd('tabnew')
  vim.cmd('tcd ' .. vim.fn.fnameescape(dir))
  M.set_tab_name(name)

  local scratch = vim.api.nvim_get_current_buf()
  vim.cmd('terminal')
  local term = vim.api.nvim_get_current_buf()
  M.set_buf_name(term, name)

  if scratch ~= term and vim.api.nvim_buf_is_valid(scratch) then
    vim.api.nvim_buf_delete(scratch, { force = true })
  end

  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('TabRename', function(opts)
  local name = opts.args
  if name == '' then
    name = vim.fn.input('Tab name: ')
  end
  M.set_tab_name(name)
end, { nargs = '?' })

return M
