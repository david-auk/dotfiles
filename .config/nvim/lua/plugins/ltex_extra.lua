return {
  {
    "barreiroleo/ltex_extra.nvim",
    ft = { "markdown", "tex", "plaintex", "text" },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ltex_plus = {
          cmd = { "ltex-ls-plus" },
          settings = {
            ltex = {
              language = "en-US",
            },
          },
          on_attach = function()
            require("ltex_extra").setup({
              server_opts = {
                name = "ltex_plus",
              },
              load_langs = { "en-US" },
              path = vim.fn.stdpath("config") .. "/spell/ltex",
            })
          end,
        },
      },
    },
  },
}
