return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",

        -- Vim-style autocomplete navigation
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },

        -- Accept selected autocomplete item
        ["<CR>"] = { "accept", "fallback" },
      },
    },
  },
}
