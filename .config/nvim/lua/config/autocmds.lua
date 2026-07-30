-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable semantic token highlighting for jdtls.
--
-- This only disables the extra LSP-based coloring, so Java highlighting falls
-- back to the native Treesitter colorscheme behavior.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client and client.name == "jdtls" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client and client.name == "jdtls" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

local eslint_fix_group = vim.api.nvim_create_augroup("EslintFixOnSave", {
  clear = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = eslint_fix_group,

  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if not client or client.name ~= "eslint" then
      return
    end

    -- Avoid duplicate save hooks if ESLint reconnects.
    vim.api.nvim_clear_autocmds({
      group = eslint_fix_group,
      event = "BufWritePre",
      buffer = event.buf,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = eslint_fix_group,
      buffer = event.buf,

      callback = function()
        vim.cmd("LspEslintFixAll")
      end,

      desc = "Fix all auto-fixable ESLint problems before saving",
    })
  end,
})
