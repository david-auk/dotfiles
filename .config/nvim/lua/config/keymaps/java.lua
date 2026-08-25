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

local function update_java_project_config()
  if not require_java_buffer() then
    return
  end

  local ok, jdtls = pcall(require, "jdtls")

  if not ok then
    vim.notify("nvim-jdtls is not available", vim.log.levels.ERROR, { title = "Java" })
    return
  end

  jdtls.update_project_config()

  vim.notify("Refreshing Gradle project configuration", vim.log.levels.INFO, { title = "Java" })
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

vim.keymap.set("n", "<leader>ju", update_java_project_config, {
  desc = "Update Java project configuration",
})

vim.keymap.set("n", "<leader>jU", function()
  gradle({
    "--refresh-dependencies",
    "dependencies",
  })
end, {
  desc = "Force refresh Gradle dependencies",
})
