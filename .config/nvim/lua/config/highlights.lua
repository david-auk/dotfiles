local function java_highlights()
  vim.api.nvim_set_hl(0, "@lsp.type.modifier.java", { link = "Keyword" })

  -- package/import path parts before the actual class
  vim.api.nvim_set_hl(0, "@variable.java", { link = "Delimiter" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = java_highlights,
})

java_highlights()
