return {
  -- Ensure pgformatter is installed through Mason.
  {
    "mason-org/mason.nvim",

    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "pgformatter") then
        table.insert(opts.ensure_installed, "pgformatter")
      end
    end,
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
}
