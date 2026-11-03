local M = {}

M.root = vim.fn.expand("~/notes")

local daily_note_path_script = vim.fn.stdpath("config") .. "/scripts/daily-note-path"

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
    return false
  end

  local result = vim.fn.writefile(lines, path)

  if result ~= 0 then
    error("Could not create file: " .. path)
  end

  return true
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

local function yesterday_date()
  local today = os.date("*t")

  -- Let mktime normalize day - 1 for us. Using noon avoids DST
  -- transitions around midnight causing surprising results.
  local yesterday = os.time({
    year = today.year,
    month = today.month,
    day = today.day - 1,
    hour = 12,
    min = 0,
    sec = 0,
  })

  return os.date("%Y-%m-%d", yesterday)
end

local function find_section(lines, title)
  local expected_heading = "## " .. title

  for index, line in ipairs(lines) do
    if vim.trim(line) == expected_heading then
      local last_line = #lines

      for next_index = index + 1, #lines do
        if lines[next_index]:match("^##%s+") then
          last_line = next_index - 1
          break
        end
      end

      return index, last_line
    end
  end

  return nil, nil
end

local function trim_blank_lines(lines)
  local first = 1
  local last = #lines

  while first <= last and lines[first]:match("^%s*$") do
    first = first + 1
  end

  while last >= first and lines[last]:match("^%s*$") do
    last = last - 1
  end

  local result = {}

  for index = first, last do
    table.insert(result, lines[index])
  end

  return result
end

local function extract_section(lines, title)
  local section_start, section_end = find_section(lines, title)

  if not section_start then
    return nil, nil
  end

  local contents = {}

  for index = section_start + 1, section_end do
    table.insert(contents, lines[index])
  end

  contents = trim_blank_lines(contents)

  local remaining = {}

  for index = 1, section_start - 1 do
    table.insert(remaining, lines[index])
  end

  for index = section_end + 1, #lines do
    table.insert(remaining, lines[index])
  end

  return contents, remaining
end

local function read_tomorrow_from_yesterday()
  local date = yesterday_date()
  local path = M.daily_note_path(date)

  if vim.fn.filereadable(path) == 0 then
    return {}, nil, nil
  end

  local lines = vim.fn.readfile(path)
  local tomorrow, remaining = extract_section(lines, "Tomorrow")

  if not tomorrow then
    return {}, nil, nil
  end

  return tomorrow, path, remaining
end

local function create_daily_note_lines(date, carried_tasks)
  local lines = {
    "# " .. date,
    "",
    "## Tasks",
    "",
  }

  if #carried_tasks > 0 then
    vim.list_extend(lines, carried_tasks)
    table.insert(lines, "")
  end

  vim.list_extend(lines, {
    "## Work log",
    "",
    "## Hobby",
    "",
    "## Notes",
    "",
    "## Tomorrow",
    "",
  })

  return lines
end

function M.daily_note_path(date)
  local command = {
    daily_note_path_script,
  }

  if date then
    table.insert(command, date)
  end

  local env = vim.fn.environ()
  env.NOTES_ROOT = M.root

  local result = vim
    .system(command, {
      text = true,
      env = env,
    })
    :wait()

  if result.code ~= 0 then
    error(vim.trim(result.stderr or "Could not determine daily note path"))
  end

  local path = vim.trim(result.stdout or "")

  if path == "" then
    error("Daily note path script returned an empty path")
  end

  return path
end

function M.today_path()
  return M.daily_note_path()
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

  local date = os.date("%Y-%m-%d")
  local path = M.today_path()
  local directory = vim.fs.dirname(path)

  vim.fn.mkdir(directory, "p")

  -- Only migrate yesterday's Tomorrow section when today's note is
  -- actually being created. Opening an existing daily note does nothing.
  if vim.fn.filereadable(path) == 0 then
    local carried_tasks, yesterday_path, yesterday_without_tomorrow = read_tomorrow_from_yesterday()

    local created = create_file_if_missing(path, create_daily_note_lines(date, carried_tasks))

    -- Create today's note first. Only remove the source section once we
    -- know its contents have safely been written to today's note.
    if created and yesterday_path then
      local result = vim.fn.writefile(yesterday_without_tomorrow, yesterday_path)

      if result ~= 0 then
        vim.notify(
          "Tasks were copied to today's note, but yesterday's Tomorrow section could not be removed",
          vim.log.levels.WARN,
          { title = "Notes" }
        )
      end
    end
  end

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
