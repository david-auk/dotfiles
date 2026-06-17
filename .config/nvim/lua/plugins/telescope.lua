local function find_files_newest_first()
  local is_mac = vim.fn.has("macunix") == 1

  local stat_command
  if is_mac then
    stat_command = "stat -f '%m %N'"
  else
    stat_command = "stat -c '%Y %n'"
  end

  return {
    "bash",
    "-lc",
    table.concat({
      "fd",
      "--type f",
      "--hidden",
      "--exclude .git",
      "--exclude node_modules",
      "--exclude __pycache__",
      "--exclude dist",
      "--exclude build",
      "--exclude target",
      "--exclude .next",
      "--exclude coverage",
      "--exec " .. stat_command .. " {}",
      "| sort -rn",
      "| sed 's/^[0-9]* //'",
    }, " "),
  }
end

return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },

  opts = {
    defaults = {
      file_ignore_patterns = {
        "^.git/",
        "^node_modules/",
        "__pycache__/",
        "%.pyc",
        "^dist/",
        "^build/",
        "^target/",
        "^.next/",
        "^coverage/",
      },
      path_display = { "smart" },
    },

    pickers = {
      find_files = {
        hidden = true,
        find_command = find_files_newest_first(),
      },
    },
  },

  config = function(_, opts)
    local telescope = require("telescope")

    telescope.setup(opts)
    telescope.load_extension("fzf")
  end,
}
