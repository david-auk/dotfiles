return {
  "artemave/workspace-diagnostics.nvim",
  keys = {
    {
      "<leader>cw",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })

        if #clients == 0 then
          vim.notify("No LSP attached to current buffer", vim.log.levels.WARN)
          return
        end

        local wd = require("workspace-diagnostics")

        for _, client in ipairs(clients) do
          wd.populate_workspace_diagnostics(client, bufnr)
        end

        vim.defer_fn(function()
          vim.cmd("Trouble diagnostics")
        end, 1000)
      end,
      desc = "Workspace Diagnostics",
    },
  },
}
