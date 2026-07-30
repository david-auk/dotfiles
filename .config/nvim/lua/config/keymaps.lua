-- LazyVim automatically loads this file on VeryLazy.
--
-- Every Lua file inside lua/config/keymaps/ is loaded recursively
-- in alphabetical order.

local keymaps_directory = vim.fn.stdpath("config") .. "/lua/config/keymaps"

local function load_keymaps(directory)
  local entries = {}

  for name, entry_type in vim.fs.dir(directory) do
    table.insert(entries, {
      name = name,
      type = entry_type,
    })
  end

  table.sort(entries, function(left, right)
    return left.name < right.name
  end)

  for _, entry in ipairs(entries) do
    local path = directory .. "/" .. entry.name

    if entry.type == "directory" then
      load_keymaps(path)
    elseif entry.type == "file" and entry.name:match("%.lua$") then
      dofile(path)
    end
  end
end

local stat = vim.uv.fs_stat(keymaps_directory)

if stat and stat.type == "directory" then
  load_keymaps(keymaps_directory)
end
