-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Selecting with the mouse copies straight to the system clipboard: when the
-- left button is released, yank the visual selection to register `+` (which
-- routes through the remote-clipboard provider), then `gv` reselects so the
-- drag behaves exactly like before. Clicks in normal mode are left alone.
vim.keymap.set("v", "<LeftRelease>", '"+ygv', {
  silent = true,
  desc = "Copy mouse selection to system clipboard",
})
