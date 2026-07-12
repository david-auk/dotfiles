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

  -- Configure pgls as an LSP server.
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

  -- Ensure pgformatter is installed through Mason.
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "pgformatter",
      },
    },
  },

  -- Use pg_format for SQL formatting.
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      opts.formatters.pg_format_local = {
        command = vim.fn.expand("~/Documents/git/hub/pgFormatter/pg_format"),
        args = {
          "--vertical-align",
          "--no-space-function",
          "-",
        },
        stdin = true,
      }

      opts.formatters_by_ft.sql = {
        "pg_format_local",
      }
    end,
  },

  -- SQL Treesitter highlighting.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "sql",
      },
    },
  },
}
