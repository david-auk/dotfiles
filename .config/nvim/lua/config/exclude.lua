-- ~/.config/nvim/lua/config/excludes.lua

local M = {}

M.directories = {
  "node_modules",
  ".git",
  "__pycache__",
  "dist",
  "build",
  "target",
  ".next",
  "coverage",
  "bin",
}

M.files = {
  ".DS_Store",
}

M.extensions = {
  "pyc",
}

local function lua_pattern_escape(value)
  return value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

function M.for_snacks_explorer()
  local result = {}

  vim.list_extend(result, M.directories)
  vim.list_extend(result, M.files)

  return result
end

function M.for_fd_exclude_args()
  local result = {}

  for _, directory in ipairs(M.directories) do
    vim.list_extend(result, { "--exclude", directory })
  end

  for _, file in ipairs(M.files) do
    vim.list_extend(result, { "--exclude", file })
  end

  for _, extension in ipairs(M.extensions) do
    vim.list_extend(result, { "--exclude", "*." .. extension })
  end

  return result
end

function M.for_telescope_file_ignore_patterns()
  local result = {}

  for _, directory in ipairs(M.directories) do
    table.insert(result, "^" .. lua_pattern_escape(directory) .. "/")
  end

  for _, file in ipairs(M.files) do
    table.insert(result, lua_pattern_escape(file) .. "$")
  end

  for _, extension in ipairs(M.extensions) do
    table.insert(result, "%." .. lua_pattern_escape(extension) .. "$")
  end

  return result
end

return M
