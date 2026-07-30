local function project_root()
  return LazyVim.root()
end

local function switch_to_previous_branch()
  local root = project_root()

  vim.system({
    "git",
    "switch",
    "-",
  }, {
    cwd = root,
    text = true,
  }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))

        vim.notify(
          message ~= "" and message or "Could not switch to the previous Git branch",
          vim.log.levels.ERROR,
          { title = "Git" }
        )

        return
      end

      -- Reload files that changed as a result of switching branches.
      vim.cmd("checktime")
      vim.cmd("redrawstatus")

      local message = vim.trim(result.stderr or result.stdout or "")

      vim.notify(message ~= "" and message or "Switched to previous branch", vim.log.levels.INFO, { title = "Git" })
    end)
  end)
end

-- Relocate Git log from <leader>gl to <leader>gL.
vim.keymap.set("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, {
  desc = "Git Log",
})

vim.keymap.set("n", "<leader>gl", switch_to_previous_branch, {
  desc = "Switch to previous Git branch",
})

vim.keymap.set("n", "<leader>ga", function()
  local file = vim.fn.expand("%:p")

  if file == "" then
    vim.notify("The current buffer has no file", vim.log.levels.WARN)
    return
  end

  vim.system({
    "git",
    "add",
    file,
  }, {
    cwd = project_root(),
    text = true,
  }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(vim.trim(result.stderr or "Could not stage current file"), vim.log.levels.ERROR, { title = "Git" })

        return
      end

      vim.notify("Staged current file", {
        title = "Git",
      })
    end)
  end)
end, {
  desc = "Git add current buffer",
})
