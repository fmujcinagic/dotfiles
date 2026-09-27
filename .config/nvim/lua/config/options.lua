-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

-- Hybrid line numbers: absolute number on the cursor line, relative numbers
-- everywhere else, so counts like `3j` can be read straight off the gutter.
vim.opt.relativenumber = true
vim.g.autoformat = false
