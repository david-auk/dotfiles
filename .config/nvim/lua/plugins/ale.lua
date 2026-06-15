return {
  {
    "dense-analysis/ale",
    ft = { "python" },
    init = function()
      vim.g.ale_linters = {
        python = { "pyright", "ruff" },
      }

      vim.g.ale_fixers = {
        python = { "ruff", "ruff_format" },
      }

      vim.g.ale_python_pyright_config = {
        python = {
          analysis = {
            autoImportCompletions = true,
            autoSearchPaths = true,
            diagnosticMode = "workspace",
            typeCheckingMode = "strict",
          },
        },
      }

      vim.g.ale_completion_enabled = 1
      vim.g.ale_fix_on_save = 1
    end,
  },
}
