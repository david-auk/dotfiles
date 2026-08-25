return {
  {
    "mason-org/mason.nvim",
    keys = {
      -- Remove LazyVim's default Mason keybind.
      { "<leader>cm", false },

      -- Move Mason to <leader>cM so <leader>cm can be used
      -- as the Markdown namespace.
      { "<leader>cM", "<cmd>Mason<cr>", desc = "Mason" },
    },
  },
}
