local state = {
  active = false,
  register = "",
  windows = {},
}

local function get_highlight(name)
  local ok, highlight = pcall(vim.api.nvim_get_hl, 0, {
    name = name,
    link = false,
  })

  if not ok then
    return {}
  end

  return highlight
end

local function define_highlights()
  local normal = get_highlight("Normal")
  local error_message = get_highlight("ErrorMsg")
  local diagnostic_error = get_highlight("DiagnosticError")

  vim.api.nvim_set_hl(0, "MacroRecordingStatus", {
    fg = normal.bg or error_message.bg,
    bg = diagnostic_error.fg or error_message.fg,
    bold = true,
  })

  local diff_delete = get_highlight("DiffDelete")
  local visual = get_highlight("Visual")
  local recording_background = diff_delete.bg or visual.bg

  vim.api.nvim_set_hl(0, "MacroRecordingCursorLine", {
    bg = recording_background,
  })

  local cursor_line_number = get_highlight("CursorLineNr")

  cursor_line_number.fg = diagnostic_error.fg or cursor_line_number.fg
  cursor_line_number.bg = recording_background or cursor_line_number.bg
  cursor_line_number.bold = true

  vim.api.nvim_set_hl(0, "MacroRecordingCursorLineNr", cursor_line_number)
end

local function override_winhighlight(value)
  local entries = {}
  local order = {}

  for entry in value:gmatch("[^,]+") do
    local source, target = entry:match("^([^:]+):(.+)$")

    if source and target then
      entries[source] = target
      table.insert(order, source)
    end
  end

  local overrides = {
    CursorLine = "MacroRecordingCursorLine",
    CursorLineNr = "MacroRecordingCursorLineNr",
  }

  for source, target in pairs(overrides) do
    if not entries[source] then
      table.insert(order, source)
    end

    entries[source] = target
  end

  local result = {}

  for _, source in ipairs(order) do
    table.insert(result, source .. ":" .. entries[source])
  end

  return table.concat(result, ",")
end

local function highlight_window(window)
  if not vim.api.nvim_win_is_valid(window) or state.windows[window] then
    return
  end

  state.windows[window] = {
    cursorline = vim.api.nvim_get_option_value("cursorline", { win = window }),
    cursorlineopt = vim.api.nvim_get_option_value("cursorlineopt", { win = window }),
    winhighlight = vim.api.nvim_get_option_value("winhighlight", { win = window }),
  }

  vim.api.nvim_set_option_value("cursorline", true, { win = window })
  vim.api.nvim_set_option_value("cursorlineopt", "line,number", { win = window })
  vim.api.nvim_set_option_value(
    "winhighlight",
    override_winhighlight(state.windows[window].winhighlight),
    { win = window }
  )
end

local function restore_windows()
  for window, options in pairs(state.windows) do
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_set_option_value("cursorline", options.cursorline, { win = window })
      vim.api.nvim_set_option_value("cursorlineopt", options.cursorlineopt, { win = window })
      vim.api.nvim_set_option_value("winhighlight", options.winhighlight, { win = window })
    end
  end

  state.windows = {}
end

local function refresh_statusline()
  vim.schedule(function()
    local ok, lualine = pcall(require, "lualine")

    if ok then
      lualine.refresh({
        place = { "statusline" },
      })
    else
      vim.cmd("redrawstatus")
    end
  end)
end

local function recording_status()
  if not state.active then
    return ""
  end

  return ("● REC @%s"):format(state.register)
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",

    init = function()
      define_highlights()

      local group = vim.api.nvim_create_augroup("MacroRecordingIndicators", {
        clear = true,
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = define_highlights,
        desc = "Refresh macro-recording highlight groups",
      })

      vim.api.nvim_create_autocmd("RecordingEnter", {
        group = group,
        callback = function()
          state.active = true
          state.register = vim.fn.reg_recording()

          highlight_window(vim.api.nvim_get_current_win())
          refresh_statusline()

          vim.notify(("Recording macro @%s"):format(state.register), vim.log.levels.WARN, {
            title = "Macro recording",
          })
        end,
        desc = "Show macro-recording indicators",
      })

      vim.api.nvim_create_autocmd("WinEnter", {
        group = group,
        callback = function()
          if state.active then
            highlight_window(vim.api.nvim_get_current_win())
          end
        end,
        desc = "Keep macro-recording indicators when changing windows",
      })

      vim.api.nvim_create_autocmd("RecordingLeave", {
        group = group,
        callback = function()
          local recorded_register = state.register

          state.active = false
          state.register = ""

          restore_windows()
          refresh_statusline()

          vim.schedule(function()
            vim.notify(("Saved macro @%s"):format(recorded_register), vim.log.levels.INFO, {
              title = "Macro recording",
            })
          end)
        end,
        desc = "Hide macro-recording indicators",
      })
    end,

    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = opts.sections.lualine_a or {}

      table.insert(opts.sections.lualine_a, 1, {
        recording_status,
        cond = function()
          return state.active
        end,
        color = "MacroRecordingStatus",
        padding = {
          left = 1,
          right = 1,
        },
      })
    end,
  },
}
