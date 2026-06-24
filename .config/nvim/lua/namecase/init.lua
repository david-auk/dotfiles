local M = {}

local function cap(word)
  return word:sub(1, 1):upper() .. word:sub(2)
end

local defaults = {
  keymap = "<leader>rN",

  cases = {
    snake = {
      label = "snake_case",
      format = function(words)
        return table.concat(words, "_")
      end,
    },

    screaming_snake = {
      label = "SCREAMING_SNAKE_CASE",
      format = function(words)
        return table.concat(words, "_"):upper()
      end,
    },

    kebab = {
      label = "kebab-case",
      format = function(words)
        return table.concat(words, "-")
      end,
    },

    camel = {
      label = "camelCase",
      format = function(words)
        local out = words[1] or ""

        for i = 2, #words do
          out = out .. cap(words[i])
        end

        return out
      end,
    },

    pascal = {
      label = "PascalCase",
      format = function(words)
        local out = {}

        for i, word in ipairs(words) do
          out[i] = cap(word)
        end

        return table.concat(out, "")
      end,
    },

    dot = {
      label = "dot.case",
      format = function(words)
        return table.concat(words, ".")
      end,
    },
  },
}

local config = vim.deepcopy(defaults)

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.detect(text)
  local value = trim(text)

  if value == "" then
    return "empty"
  end

  if value:find("_") and not value:find("%-") then
    if value:match("^[A-Z0-9_]+$") then
      return "screaming_snake"
    end

    return "snake"
  end

  if value:find("%-") and not value:find("_") then
    return "kebab"
  end

  if value:match("^[A-Z][A-Za-z0-9]*$") then
    return "pascal"
  end

  if value:match("^[a-z][A-Za-z0-9]*$") and value:find("[A-Z]") then
    return "camel"
  end

  return "unknown"
end

function M.to_words(text)
  local value = trim(text)

  -- HTTPServer -> HTTP Server
  -- TestFile   -> Test File
  value = value:gsub("([A-Z]+)([A-Z][a-z])", "%1 %2")

  -- testFile -> test File
  value = value:gsub("([a-z0-9])([A-Z])", "%1 %2")

  -- test_file / test-file / test.file / spaces
  value = value:gsub("[_%-%s%.]+", " ")

  local words = {}

  for word in value:gmatch("%S+") do
    word = word:gsub("[^%w]", "")

    if word ~= "" then
      table.insert(words, word:lower())
    end
  end

  return words
end

function M.convert(text, target_case)
  local case = config.cases[target_case]

  if not case then
    error(("Unknown target case: %s"):format(target_case))
  end

  local leading = text:match("^%s*") or ""
  local trailing = text:match("%s*$") or ""
  local words = M.to_words(text)

  if #words == 0 then
    return text
  end

  return leading .. case.format(words) .. trailing
end

local function get_visual_range()
  local mode = vim.fn.visualmode()

  if mode == string.char(22) then
    vim.notify("Blockwise visual selections are not supported yet", vim.log.levels.WARN)
    return nil
  end

  local buf = vim.api.nvim_get_current_buf()

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  if mode == "V" then
    start_col = 0

    local last_line = vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or ""
    end_col = #last_line
  else
    -- Visual char selections are inclusive, but nvim_buf_get_text expects end-exclusive.
    end_col = end_col + 1
  end

  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  local text = table.concat(lines, "\n")

  return {
    buf = buf,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    text = text,
  }
end

local function replace_range(range, target_case)
  local converted = M.convert(range.text, target_case)
  local replacement = vim.split(converted, "\n", { plain = true })

  vim.api.nvim_buf_set_text(range.buf, range.start_row, range.start_col, range.end_row, range.end_col, replacement)
end

function M.replace_visual(target_case)
  local range = get_visual_range()

  if not range then
    return
  end

  replace_range(range, target_case)
end

function M.pick_visual()
  local range = get_visual_range()

  if not range then
    return
  end

  local items = {}

  for key, case in pairs(config.cases) do
    table.insert(items, {
      key = key,
      label = case.label,
    })
  end

  table.sort(items, function(a, b)
    return a.label < b.label
  end)

  local detected = M.detect(range.text)

  vim.ui.select(items, {
    prompt = ("Convert case, detected: %s"):format(detected),
    kind = "namecase",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    replace_range(range, choice.key)
  end)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  vim.keymap.set("x", config.keymap, function()
    M.pick_visual()
  end, {
    desc = "Convert selected text naming style",
  })
end

return M
