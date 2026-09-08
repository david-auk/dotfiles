local function publish_diagnostics(err, result, ctx)
  if result and result.diagnostics then
    result.diagnostics = vim.tbl_filter(function(diagnostic)
      if diagnostic.code ~= "UPPERCASE_SENTENCE_START" then
        return true
      end

      local start = diagnostic.range and diagnostic.range.start

      if not start then
        return true
      end

      local bufnr = ctx.bufnr

      if not bufnr or vim.bo[bufnr].filetype ~= "markdown" then
        return true
      end

      local line = vim.api.nvim_buf_get_lines(bufnr, start.line, start.line + 1, false)[1] or ""

      -- LSP character positions are zero-based.
      local prefix = line:sub(1, start.character + 1)

      -- Ignore UPPERCASE_SENTENCE_START when LTeX interprets the `x`
      -- inside a completed Markdown task checkbox as sentence text.
      local is_completed_task = prefix:match("^%s*[-+*]%s+%[[xX]%]$") ~= nil
        or prefix:match("^%s*%d+[.)]%s+%[[xX]%]$") ~= nil

      return not is_completed_task
    end, result.diagnostics)
  end

  vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx)
end

return {
  {
    "neovim/nvim-lspconfig",

    opts = {
      servers = {
        ltex_plus = {
          handlers = {
            ["textDocument/publishDiagnostics"] = publish_diagnostics,
          },
        },
      },
    },
  },
}
