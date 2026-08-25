local pgls_bin = vim.fn.stdpath("data") .. "/pgls/bin/pgls"

return {
  -- pgls is not currently available through Mason, so let Lazy.nvim
  -- download its repository and compile the binary automatically.
  {
    "winebarrel/pgls",
    name = "pgls",
    version = "v0.5.0",
    lazy = true,
    module = false,

    build = function(plugin)
      local bin_dir = vim.fs.dirname(pgls_bin)
      vim.fn.mkdir(bin_dir, "p")

      local result = vim
        .system({
          "go",
          "build",
          "-o",
          pgls_bin,
          ".",
        }, {
          cwd = plugin.dir,
          text = true,
        })
        :wait()

      if result.code ~= 0 then
        error("Failed to build pgls:\n" .. (result.stderr or result.stdout or "Unknown error"))
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pgls = {
          -- Prevent LazyVim from asking Mason to install it.
          mason = false,

          cmd = { pgls_bin },
          filetypes = { "sql" },

          -- Only activate inside projects configured for pgls.
          root_markers = {
            ".pgls.json",
          },

          workspace_required = true,
        },
      },
    },
  },
}
