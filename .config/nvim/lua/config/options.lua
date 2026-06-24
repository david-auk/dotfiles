-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LSP Server to use for Rust.
-- Set to "bacon-ls" to use bacon-ls instead of rust-analyzer.
-- only for diagnostics. The rest of LSP support will still be
-- provided by rust-analyzer.
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

-- Use BasedPyright instead of Pyright for better Python import code actions.
vim.g.lazyvim_python_lsp = "basedpyright"

-- Keep using Ruff as the linter / formatter / import organizer.
vim.g.lazyvim_python_ruff = "ruff"
