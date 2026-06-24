local function java_dropbar_root(buf, win)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return vim.fn.getcwd()
  end

  path = vim.fs.normalize(path):gsub("\\", "/")

  -- Keep this small and explicit.
  -- Full path:
  --   .../src/main/java/nl/lekkeratlas/backendapi/service/ContentService.java
  --
  -- Dropbar root:
  --   .../src/main/java/nl/lekkeratlas
  --
  -- Display:
  --   backendapi/service/ContentService.java
  local java_prefixes = {
    "/src/main/java/nl/lekkeratlas/",
    "/src/test/java/nl/lekkeratlas/",
  }

  for _, marker in ipairs(java_prefixes) do
    local start_pos, end_pos = path:find(marker, 1, true)
    if start_pos then
      return path:sub(1, end_pos - 1)
    end
  end

  -- Fallback to the window cwd, matching dropbar's default behavior.
  local ok, cwd = pcall(vim.fn.getcwd, win)
  return ok and cwd or vim.fn.getcwd()
end

return {
  {
    "Bekaboo/dropbar.nvim",
    opts = {
      bar = {
        update_debounce = 80,
        hover = false,
      },

      sources = {
        path = {
          relative_to = java_dropbar_root,
        },
      },

      menu = {
        preview = false,
        hover = false,
      },
    },
    config = function(_, opts)
      require("dropbar").setup(opts)

      local api = require("dropbar.api")

      vim.keymap.set("n", "<leader>;", api.pick, {
        desc = "Pick symbols in winbar",
      })

      vim.keymap.set("n", "[;", api.goto_context_start, {
        desc = "Go to start of current context",
      })

      vim.keymap.set("n", "];", api.select_next_context, {
        desc = "Select next context",
      })
    end,
  },
}
