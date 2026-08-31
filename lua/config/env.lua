-- Environment setup: prepend build tools (conda mingw toolchain, make) and
-- Mason's bin dir to PATH so lazy builds (telescope-fzf-native) and the
-- nvim-treesitter parser compilation (`tree-sitter`, `cc`) succeed on Windows.
local PATH_SEP = ';'

local function prepend_path(dir)
  if dir == '' or vim.fn.isdirectory(dir) ~= 1 then
    return
  end
  if not vim.env.PATH:match('(^' .. PATH_SEP .. '?)(' .. vim.pesc(dir) .. ')(' .. PATH_SEP .. '|$)') then
    vim.env.PATH = dir .. PATH_SEP .. vim.env.PATH
  end
end

-- conda prefix: honor the env, else infer from the running nvim's location
-- (this config's nvim lives at <prefix>/Library/bin/nvim.exe)
local conda = vim.env.CONDA_PREFIX
if conda == nil or conda == '' then
  conda = vim.fn.fnamemodify(vim.v.progpath, ':p:h:h:h')
end

if conda ~= '' and vim.fn.isdirectory(conda .. '/Library') == 1 then
  -- conda root + Scripts (python, conda) and toolchain
  prepend_path(conda)
  prepend_path(conda .. '/Scripts')
  prepend_path(conda .. '/Library/bin')
  prepend_path(conda .. '/Library/usr/bin')

  -- conda win-cross gcc needs the mingw sysroot on its library search path
  local sysroot_lib = conda .. '/Library/x86_64-w64-mingw32/sysroot/usr/lib'
  if vim.fn.isdirectory(sysroot_lib) == 1 and not (vim.env.LIBRARY_PATH or ''):match(vim.pesc(sysroot_lib)) then
    vim.env.LIBRARY_PATH = sysroot_lib .. (vim.env.LIBRARY_PATH and (PATH_SEP .. vim.env.LIBRARY_PATH) or '')
  end

  -- sqlite.lua / telescope-zotero need a sqlite3 clib on Windows
  local sqlite_clib = conda .. '/Library/bin/sqlite3.dll'
  if vim.g.sqlite_clib_path == nil and vim.fn.filereadable(sqlite_clib) == 1 then
    vim.g.sqlite_clib_path = sqlite_clib
  end
end

-- tree-sitter-cli uses $CC to pick a C compiler (defaults to MSVC cl.exe)
if vim.fn.executable('gcc') == 1 then
  vim.env.CC = vim.env.CC or 'gcc'
end

-- Mason-managed CLI tools (tree-sitter-cli, etc.)
prepend_path(vim.fn.stdpath('data') .. '/mason/bin')

-- opencode binary (default install to ~/.opencode/bin/opencode.exe on Windows)
-- checkhealth expects `opencode` on $PATH; Windows PATHEXT resolves .exe
prepend_path(vim.fn.expand('~/.opencode/bin'))
prepend_path(vim.fn.expand('~/.opencode'))