local M = {}

local last_linted_version = {}

local function normalize(path)
  if not path or path == "" then
    return ""
  end

  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function relative_path(root, filename)
  if vim.fs.relpath then
    return vim.fs.relpath(root, filename) or filename
  end

  local prefix = root .. "/"

  if vim.startswith(filename, prefix) then
    return filename:sub(#prefix + 1)
  end

  return filename
end

local function read_project(filename)
  local config_path = vim.fs.find(".pgls.json", {
    path = vim.fs.dirname(filename),
    upward = true,
    type = "file",
  })[1]

  if not config_path then
    return nil
  end

  local read_ok, contents = pcall(vim.fn.readfile, config_path)

  if not read_ok then
    return nil
  end

  local decode_ok, config = pcall(vim.json.decode, table.concat(contents, "\n"))

  if not decode_ok or type(config) ~= "table" then
    return nil
  end

  if type(config.schemaDir) ~= "string" or config.schemaDir == "" then
    return nil
  end

  local root = normalize(vim.fs.dirname(config_path))
  local schema_dir

  if config.schemaDir:sub(1, 1) == "/" then
    schema_dir = normalize(config.schemaDir)
  else
    schema_dir = normalize(root .. "/" .. config.schemaDir)
  end

  -- Match pgls's safety requirement: schemaDir must remain inside
  -- the workspace.
  if not vim.startswith(schema_dir .. "/", root .. "/") then
    return nil
  end

  return {
    root = root,
    schema_dir = schema_dir,
  }
end

local function require_current_project()
  local filename = normalize(vim.api.nvim_buf_get_name(0))
  local project = read_project(filename)

  if not project then
    error("Could not read schemaDir from .pgls.json")
  end

  return filename, project
end

local function parse_postgres_output(output, bufnr, linter_cwd)
  local diagnostics = {}
  local current_file = normalize(vim.api.nvim_buf_get_name(bufnr))
  local current_diagnostic

  for line in
    vim.gsplit(output or "", "\n", {
      plain = true,
      trimempty = true,
    })
  do
    local filename, line_number, level, message = line:match("^psql:(.-):(%d+):%s+(%u+):%s+(.+)$")

    if filename and (level == "ERROR" or level == "FATAL") then
      if not filename:match("^/") then
        filename = linter_cwd .. "/" .. filename
      end

      filename = normalize(filename)

      local is_current_file = filename == current_file
      local diagnostic_line = math.max(tonumber(line_number) - 1, 0)

      if not is_current_file then
        message = string.format("%s:%s: %s", relative_path(linter_cwd, filename), line_number, message)

        -- nvim-lint publishes diagnostics to the buffer that initiated
        -- the lint run. Put cross-file errors on its first line and
        -- include the actual source location in the message.
        diagnostic_line = 0
      end

      current_diagnostic = {
        lnum = diagnostic_line,
        col = 0,
        severity = vim.diagnostic.severity.ERROR,
        source = "postgres-schema",
        message = message,
      }

      table.insert(diagnostics, current_diagnostic)
    elseif current_diagnostic then
      local continuation = line:match("^(DETAIL:%s+.+)$")
        or line:match("^(HINT:%s+.+)$")
        or line:match("^(CONTEXT:%s+.+)$")

      if continuation then
        current_diagnostic.message = current_diagnostic.message .. "\n" .. continuation
      end
    end
  end

  return diagnostics
end

local function should_lint(ctx)
  local filename = normalize(ctx.filename)

  if filename == "" then
    return false
  end

  local project = read_project(filename)

  if not project then
    return false
  end

  -- Only validate SQL files that belong to schemaDir.
  if not vim.startswith(filename, project.schema_dir .. "/") then
    return false
  end

  -- LazyVim may also invoke linters on InsertLeave. Only rerun the
  -- relatively expensive Docker validation when the saved file changed.
  local stat = vim.uv.fs_stat(filename)

  if not stat then
    return false
  end

  local version = table.concat({
    stat.mtime.sec,
    stat.mtime.nsec,
    stat.size,
  }, ":")

  if last_linted_version[filename] == version then
    return false
  end

  last_linted_version[filename] = version
  return true
end

function M.create_linter(script)
  return {
    cmd = script,

    args = {
      function()
        local _, project = require_current_project()
        return project.root
      end,

      function()
        local _, project = require_current_project()
        return project.schema_dir
      end,

      function()
        local filename = normalize(vim.api.nvim_buf_get_name(0))

        return filename
      end,
    },

    stdin = false,
    append_fname = false,
    stream = "both",
    ignore_exitcode = true,

    parser = parse_postgres_output,
    condition = should_lint,
  }
end

return M
