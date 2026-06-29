local excludes = require("config.excludes")

local function find_files_newest_first()
  local is_mac = vim.fn.has("macunix") == 1

  local stat_command
  if is_mac then
    stat_command = "stat -f '%m %N'"
  else
    stat_command = "stat -c '%Y %n'"
  end

  local command = {
    "fd",
    "--type",
    "f",
    "--hidden",
  }

  vim.list_extend(command, excludes.for_fd_exclude_args())

  vim.list_extend(command, {
    "--exec",
    stat_command,
    "{}",
    "| sort -rn",
    "| sed 's/^[0-9]* //'",
  })

  return {
    "bash",
    "-lc",
    table.concat(command, " "),
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
      file_ignore_patterns = excludes.for_telescope_file_ignore_patterns(),
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
