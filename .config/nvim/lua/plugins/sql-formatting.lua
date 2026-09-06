return {
  {
    "mason-org/mason.nvim",

    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "pgformatter") then
        table.insert(opts.ensure_installed, "pgformatter")
      end
    end,
  },

  {
    "stevearc/conform.nvim",

    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      opts.formatters.pg_format = {
        prepend_args = {
          "--vertical-align",
          "--no-space-function",
          "--format-type",
          "--comma-break",
          "--keep-newline",
        },
      }

      opts.formatters_by_ft.sql = {
        "pg_format",
      }
    end,
  },
}
