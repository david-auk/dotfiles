-- Tmux navigation

vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", {
  desc = "Tmux Navigate Left",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", {
  desc = "Tmux Navigate Down",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", {
  desc = "Tmux Navigate Up",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", {
  desc = "Tmux Navigate Right",
  remap = false,
  silent = true,
})

-- Aliases for LazyVim's Git hunk navigation.

vim.keymap.set("n", "]g", "]h", {
  remap = true,
  silent = true,
  desc = "Next Git hunk",
})

vim.keymap.set("n", "[g", "[h", {
  remap = true,
  silent = true,
  desc = "Previous Git hunk",
})
