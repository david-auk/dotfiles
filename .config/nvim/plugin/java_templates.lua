local function get_package_from_path(path)
  path = path:gsub("\\", "/")

  local roots = {
    "/src/main/java/",
    "/src/test/java/",
  }

  for _, root in ipairs(roots) do
    local root_start = path:find(root, 1, true)

    if root_start then
      local relative_path = path:sub(root_start + #root)
      local package_path = relative_path:match("(.+)/[^/]+%.java$")

      if package_path and package_path ~= "" then
        return package_path:gsub("/", ".")
      end
    end
  end

  return nil
end

local function get_class_name()
  return vim.fn.expand("%:t:r")
end

local function build_template(kind)
  local class_name = get_class_name()
  local package_name = get_package_from_path(vim.api.nvim_buf_get_name(0))

  if class_name == "" then
    return nil
  end

  local lines = {}

  if package_name then
    table.insert(lines, "package " .. package_name .. ";")
    table.insert(lines, "")
  end

  if kind == "interface" then
    vim.list_extend(lines, {
      "public interface " .. class_name .. " {",
      "}",
    })
  elseif kind == "enum" then
    vim.list_extend(lines, {
      "public enum " .. class_name .. " {",
      "}",
    })
  elseif kind == "record" then
    vim.list_extend(lines, {
      "public record " .. class_name .. "() {",
      "}",
    })
  else
    vim.list_extend(lines, {
      "public class " .. class_name .. " {",
      "",
      "    public " .. class_name .. "() {",
      "    }",
      "}",
    })
  end

  return lines
end

local function insert_java_template(kind, opts)
  opts = opts or {}

  if vim.b.java_template_inserted and not opts.force then
    return
  end

  local is_empty = vim.fn.line("$") == 1 and vim.fn.getline(1) == ""

  if not is_empty and not opts.force then
    if not opts.silent then
      vim.notify(
        "Java buffer is not empty. Use :JavaBoilerplate! " .. (kind or "class") .. " to overwrite it.",
        vim.log.levels.WARN
      )
    end

    return
  end

  local lines = build_template(kind or "class")

  if not lines then
    return
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  vim.b.java_template_inserted = true

  local target_line = #lines - 1
  vim.api.nvim_win_set_cursor(0, { target_line, 4 })
end

vim.api.nvim_create_user_command("JavaBoilerplate", function(opts)
  local kind = opts.args ~= "" and opts.args or "class"

  insert_java_template(kind, {
    force = opts.bang,
    silent = false,
  })
end, {
  nargs = "?",
  bang = true,
  complete = function()
    return { "class", "interface", "enum", "record" }
  end,
})

local java_template_group = vim.api.nvim_create_augroup("JavaBoilerplate", {
  clear = true,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufEnter" }, {
  group = java_template_group,
  pattern = "*.java",
  callback = function()
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(0) then
        return
      end

      insert_java_template("class", {
        force = false,
        silent = true,
      })
    end)
  end,
})
