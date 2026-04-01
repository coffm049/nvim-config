vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  pattern = { '*' },
  command = 'checktime',
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  group = vim.api.nvim_create_augroup("MyTerminalSettings", { clear = true }),
  pattern = { "*" },
  callback = function()
    local opts = { buffer = true, silent = true }
    
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)

    vim.keymap.set("n", "H", ":tabprevious<CR>", opts)
    vim.keymap.set("n", "L", ":tabnext<CR>", opts)

    if string.match(vim.api.nvim_buf_get_name(0), "opencode") then
      vim.keymap.set("n", "<Esc>", "i<Esc>", opts)
      vim.keymap.set("t", "<C-Esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "I", [[<Esc>]], opts)
    end
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
