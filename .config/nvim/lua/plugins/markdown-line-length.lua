return {
  -- Reflow Markdown prose without changing Prettier's behavior for other files.
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}

      opts.formatters.markdown_prettier = {
        inherit = "prettier",
        prepend_args = { "--prose-wrap", "always", "--print-width", "80" },
      }

      -- Keep LazyVim's Markdown lint fixes and TOC formatter in the pipeline.
      opts.formatters_by_ft.markdown = { "markdown_prettier", "markdownlint-cli2", "markdown-toc" }
      opts.formatters_by_ft["markdown.mdx"] = { "markdown_prettier", "markdownlint-cli2", "markdown-toc" }
    end,
  },

  -- markdownlint's MD013 has no built-in fix. Expose the same formatter as a
  -- regular LSP quickfix when the cursor is on an MD013 diagnostic.
  {
    "geodimm/lint-actions.nvim",
    ft = { "markdown", "markdown.mdx" },
    config = function()
      local lint_actions = require("lint_actions")
      lint_actions.setup()

      vim.lsp.commands["markdown.wrap80"] = function(_, context)
        require("conform").format({
          bufnr = context.bufnr,
          formatters = { "markdown_prettier" },
          lsp_format = "never",
          async = false,
          timeout_ms = 2000,
        })
      end

      lint_actions.register({
        source = "markdown-md013",
        filetypes = { "markdown", "markdown.mdx" },
        provide = function(context)
          if not context.range then
            return {}
          end

          local first_line = context.range.start.line
          local last_line = context.range["end"].line

          for _, diagnostic in ipairs(vim.diagnostic.get(context.bufnr)) do
            if
              tostring(diagnostic.code or ""):match("^MD013")
              and diagnostic.lnum >= first_line
              and diagnostic.lnum <= last_line
            then
              return {
                {
                  range = {
                    start = { line = diagnostic.lnum, character = 0 },
                    ["end"] = { line = diagnostic.lnum, character = 0 },
                  },
                  action = {
                    title = "Wrap Markdown prose to 80 columns (MD013)",
                    kind = "quickfix",
                    command = {
                      title = "Wrap Markdown prose to 80 columns",
                      command = "markdown.wrap80",
                    },
                  },
                },
              }
            end
          end

          return {}
        end,
      })
    end,
  },
}
