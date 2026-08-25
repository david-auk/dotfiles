local postgres_lint = require("config.sql.postgres_lint")

return {
  {
    "mfussenegger/nvim-lint",

    opts = function(_, opts)
      local script = vim.fn.stdpath("config") .. "/scripts/lint-postgres-schema"

      opts.linters = opts.linters or {}

      opts.linters.postgres_schema = postgres_lint.create_linter(script)

      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.sql = opts.linters_by_ft.sql or {}

      if not vim.tbl_contains(opts.linters_by_ft.sql, "postgres_schema") then
        table.insert(opts.linters_by_ft.sql, "postgres_schema")
      end
    end,
  },
}
