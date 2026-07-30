-- this is needed to support my habit of deleting entire words with opt-backspace
vim.keymap.set({ "i", "c", "t" }, "<M-BS>", "<C-w>", {
  desc = "Delete previous word",
})
