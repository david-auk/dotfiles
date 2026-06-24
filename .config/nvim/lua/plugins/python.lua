return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              -- Let Ruff handle import sorting so the two servers do not fight.
              disableOrganizeImports = true,

              analysis = {
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },

        ruff = {
          init_options = {
            settings = {
              fixAll = true,
              organizeImports = true,
            },
          },
        },
      },
    },
  },
}
