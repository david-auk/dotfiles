local notes = require("config.notes")

vim.keymap.set("n", "<leader>ni", notes.open_index, {
  desc = "Notes index",
})

vim.keymap.set("n", "<leader>nn", notes.find_notes, {
  desc = "Find notes",
})

vim.keymap.set("n", "<leader>ng", notes.grep_notes, {
  desc = "Grep notes",
})

vim.keymap.set("n", "<leader>nd", notes.open_today, {
  desc = "Daily note",
})

vim.keymap.set("n", "<leader>nx", notes.open_inbox, {
  desc = "Notes inbox",
})

vim.keymap.set("n", "<leader>nc", notes.new_note, {
  desc = "Create note",
})

vim.keymap.set("n", "<leader>np", notes.find_project_notes, {
  desc = "Project notes",
})
