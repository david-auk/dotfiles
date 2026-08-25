return {
  {
    -- blink.cmp is the completion engine used by LazyVim.
    --
    -- It displays autocomplete suggestions from sources such as the LSP,
    -- snippets, paths, and words from the current buffer.
    --
    -- Blink also controls keys that interact with completion. A keymap can
    -- contain multiple actions, which are attempted from left to right until
    -- one handles the keypress.
    "saghen/blink.cmp",

    opts = {
      keymap = {
        preset = "default",

        -- Vim-style completion navigation.
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },

        -- Enter is handled in the following order:
        --
        -- 1. Accept the currently selected Blink completion.
        --
        -- 2. When editing a Markdown list, let markdown-plus handle Enter so
        --    the list automatically continues:
        --
        --      - first item|
        --
        --    becomes:
        --
        --      - first item
        --      - |
        --
        -- 3. If neither applies, fall back to the next <CR> mapping. This
        --    preserves MiniPairs and ultimately Neovim's normal Enter.
        ["<CR>"] = {
          "accept",

          function()
            -- markdown-plus is only loaded for Markdown buffers.
            if vim.bo.filetype ~= "markdown" then
              return false
            end

            local ok, markdown_plus = pcall(require, "markdown-plus")
            if not ok then
              return false
            end

            -- markdown-plus exposes this predicate specifically for plugins
            -- that need to decide whether it would handle Enter itself.
            if not markdown_plus.in_list_context("enter") then
              return false
            end

            -- <Plug>(...) is a Neovim mapping, not literal text.
            --
            -- Convert the special-key notation into Neovim's internal key
            -- representation and feed it back with remapping enabled ("m").
            -- This causes the markdown-plus <Plug> mapping to execute.
            local keys = vim.api.nvim_replace_termcodes("<Plug>(MarkdownPlusListEnter)", true, false, true)

            vim.api.nvim_feedkeys(keys, "m", false)

            -- Tell Blink that this keypress has been handled so it doesn't
            -- continue to the "fallback" action below.
            return true
          end,

          -- Let MiniPairs / Neovim handle ordinary Enter.
          "fallback",
        },
      },
    },
  },
}
