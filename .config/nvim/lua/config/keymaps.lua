-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<leader>uS", require("Snacks.dashboard").open, { desc = "Open mini starter" })

vim.keymap.set("n", "<leader>dd", function()
  vim.cmd("%bd")
  vim.fn.chdir(vim.fn.expand("~"))
  Snacks.dashboard.open()
end, { desc = "Open dashboard from home directory" })

-- E = jump to last non-blank character of current line
vim.keymap.set({ "n", "x", "o" }, "E", "g_", {
  desc = "Go to last non-blank character of line",
})

-- B = jump to first non-blank character of current line
vim.keymap.set({ "n", "x", "o" }, "B", "^", {
  desc = "Go to first non-blank character of line",
})

-- Load custom namecase selector
require("namecase").setup({
  keymap = "<leader>rN",
})

-- Tmux navigation
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Tmux Navigate Left", remap = false, silent = true })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Tmux Navigate Down", remap = false, silent = true })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Tmux Navigate Up", remap = false, silent = true })
vim.keymap.set(
  "n",
  "<C-l>",
  "<cmd>TmuxNavigateRight<cr>",
  { desc = "Tmux Navigate Right", remap = false, silent = true }
)

-- Java / Gradle helpers

local function project_root()
  return LazyVim.root()
end

local function gradle(args)
  local root = project_root()
  local wrapper = root .. "/gradlew"

  local cmd
  if vim.fn.filereadable(wrapper) == 1 then
    cmd = { "./gradlew" }
  else
    cmd = { "gradle" }
  end

  vim.list_extend(cmd, args)

  Snacks.terminal.open(cmd, {
    cwd = root,
    auto_close = false,
    win = {
      position = "bottom",
    },
  })
end

local function require_java_buffer()
  if vim.bo.filetype ~= "java" then
    vim.notify("Open/focus a .java file first. Current filetype is: " .. vim.bo.filetype, vim.log.levels.WARN)
    return false
  end

  return true
end

local function setup_java_main_configs()
  if not require_java_buffer() then
    return false
  end

  local ok, jdtls_dap = pcall(require, "jdtls.dap")
  if not ok then
    vim.notify("jdtls.dap is not available. Is the LazyVim Java extra enabled?", vim.log.levels.ERROR)
    return false
  end

  jdtls_dap.setup_dap_main_class_configs()
  return true
end

-- IntelliJ-like: Build Project
vim.keymap.set("n", "<leader>jb", function()
  gradle({ "build" })
end, { desc = "Gradle build" })

-- IntelliJ-like: Rebuild Project
vim.keymap.set("n", "<leader>jB", function()
  gradle({ "clean", "build" })
end, { desc = "Gradle clean build" })

-- Useful for Spring Boot projects
vim.keymap.set("n", "<leader>js", function()
  gradle({ "bootRun" })
end, { desc = "Gradle bootRun" })

-- If your project uses the Gradle application plugin
vim.keymap.set("n", "<leader>ja", function()
  gradle({ "run" })
end, { desc = "Gradle run" })

-- Pick/discover a Java main class.
-- IMPORTANT: use this from a .java file, not build.gradle.
vim.keymap.set("n", "<leader>jR", function()
  if not setup_java_main_configs() then
    return
  end

  vim.cmd("DapNew")
end, { desc = "Pick Java main class" })

-- Run/debug the selected Java configuration again.
vim.keymap.set("n", "<leader>jr", function()
  if not setup_java_main_configs() then
    return
  end

  require("dap").continue()
end, { desc = "Run/debug Java main" })

-- Optional: Java test shortcuts
vim.keymap.set("n", "<leader>jt", function()
  if not require_java_buffer() then
    return
  end

  require("jdtls").test_nearest_method()
end, { desc = "Run nearest Java test" })

vim.keymap.set("n", "<leader>jT", function()
  if not require_java_buffer() then
    return
  end

  require("jdtls").test_class()
end, { desc = "Run Java test class" })

-- Git custom bindings

vim.keymap.set("n", "<leader>ga", function()
  vim.cmd("silent !git add " .. vim.fn.shellescape(vim.fn.expand("%:p")))
  vim.notify("Staged current file")
end, {
  desc = "Git add current buffer",
})
