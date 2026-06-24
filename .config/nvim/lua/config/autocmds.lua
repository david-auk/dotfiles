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
