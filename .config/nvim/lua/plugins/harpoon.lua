-- Harpoon v2: ThePrimeagen-style fast navigation between project hot files.
-- LazyVim auto-imports this file. Keymaps avoid LazyVim defaults (buffer
-- switching owns <leader>1-9, window nav owns C-h/j/k/l), so slots live
-- under <leader>h.
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_window_with_cwd = true,
      },
    })
    local map = vim.keymap.set
    map("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: add file" })
    map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon: quick menu" })
    map("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon: quick menu" })
    for i, key in ipairs({ "1", "2", "3", "4" }) do
      map("n", "<leader>h" .. key, function() harpoon:list():select(i) end, { desc = "Harpoon: slot " .. i })
    end
    map("n", "<leader>hp", function() harpoon:list():prev() end, { desc = "Harpoon: prev" })
    map("n", "<leader>hn", function() harpoon:list():next() end, { desc = "Harpoon: next" })
  end,
}
