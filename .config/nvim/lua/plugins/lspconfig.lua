return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      jdtls = {
        settings = {
          java = {
            completion = {
              importOrder = {
                "java",
                "javax",
                "org",
                "com",
                "io",
                "nl",
              },
            },
          },
        },
      },
    },
    setup = {
      jdtls = function()
        return true -- avoid duplicate servers
      end,
    },
  },

  init = function()
    local function restart_jdtls()
      vim.schedule(function()
        vim.cmd("silent! checktime")
        vim.cmd("silent! LspRestart jdtls")
      end)
    end

    vim.api.nvim_create_autocmd("BufNewFile", {
      pattern = "*.java",
      callback = restart_jdtls,
      desc = "Restart jdtls when Java files are created",
    })

    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
      pattern = "*.java",
      callback = function(args)
        local path = vim.api.nvim_buf_get_name(args.buf)

        if path ~= "" and vim.fn.filereadable(path) == 0 then
          restart_jdtls()
        else
          vim.cmd("silent! checktime")
        end
      end,
      desc = "Refresh Java buffers and restart jdtls when file path is broken",
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.java",
      callback = function()
        vim.lsp.buf.code_action({
          context = {
            only = { "source.organizeImports" },
            diagnostics = {},
          },
          apply = true,
        })
      end,
      desc = "Organize Java imports on save",
    })
  end,
}
