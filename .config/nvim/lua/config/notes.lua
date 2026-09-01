local M = {}

M.root = vim.fn.expand("~/notes")

local directories = {
  "archive",
  "areas",
  "daily",
  "inbox",
  "projects",
  "reference",
  "templates",
}

local function open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function create_file_if_missing(path, lines)
  if vim.fn.filereadable(path) == 1 then
    return
  end

  vim.fn.writefile(lines, path)
end

local function ensure_structure()
  vim.fn.mkdir(M.root, "p")

  for _, directory in ipairs(directories) do
    vim.fn.mkdir(M.root .. "/" .. directory, "p")
  end

  create_file_if_missing(M.root .. "/index.md", {
    "# Notes",
    "",
    "## Projects",
    "",
    "## Areas",
    "",
    "## Reference",
    "",
    "## Inbox",
    "",
    "- [[inbox/quick-notes]]",
    "",
  })

  create_file_if_missing(M.root .. "/inbox/quick-notes.md", {
    "# Quick Notes",
    "",
  })
end

local function slugify(value)
  return value:lower():gsub("%s+", "-"):gsub("[^%w%-]", ""):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
end

function M.open_index()
  ensure_structure()
  open(M.root .. "/index.md")
end

function M.open_inbox()
  ensure_structure()
  open(M.root .. "/inbox/quick-notes.md")
end

function M.open_today()
  ensure_structure()

  local year = os.date("%Y")
  local month = os.date("%m")
  local date = os.date("%Y-%m-%d")

  local directory = string.format("%s/daily/%s/%s", M.root, year, month)
  local path = string.format("%s/%s.md", directory, date)

  vim.fn.mkdir(directory, "p")

  create_file_if_missing(path, {
    "# " .. date,
    "",
    "## Tasks",
    "",
    "## Work log",
    "",
    "## Notes",
    "",
    "## Tomorrow",
    "",
  })

  open(path)
end

function M.new_note()
  ensure_structure()

  vim.ui.input({
    prompt = "Note name: ",
  }, function(input)
    if not input then
      return
    end

    input = vim.trim(input)

    if input == "" then
      return
    end

    local filename = slugify(input)

    if filename == "" then
      vim.notify("Could not create a valid note filename", vim.log.levels.WARN, {
        title = "Notes",
      })

      return
    end

    local path = string.format("%s/inbox/%s.md", M.root, filename)

    create_file_if_missing(path, {
      "# " .. input,
      "",
    })

    open(path)
  end)
end

function M.find_notes()
  ensure_structure()

  require("telescope.builtin").find_files({
    prompt_title = "Notes",
    cwd = M.root,
    hidden = false,
  })
end

function M.grep_notes()
  ensure_structure()

  require("telescope.builtin").live_grep({
    prompt_title = "Search Notes",
    cwd = M.root,
  })
end

function M.find_project_notes()
  ensure_structure()

  require("telescope.builtin").find_files({
    prompt_title = "Project Notes",
    cwd = M.root .. "/projects",
    hidden = false,
  })
end

ensure_structure()

return M
