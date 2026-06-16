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
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  },

  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("fzf")
  end,
}
