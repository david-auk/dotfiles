return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = opts.picker.sources.explorer or {}

      local explorer = opts.picker.sources.explorer

      explorer.actions = explorer.actions or {}

      local function tmux_or_wincmd(tmux_direction, vim_direction)
        if vim.env.TMUX then
          vim.fn.system("tmux select-pane -" .. tmux_direction)
        else
          vim.cmd("wincmd " .. vim_direction)
        end
      end

      explorer.actions.tmux_left_pane = function()
        tmux_or_wincmd("L", "h")
      end

      explorer.actions.tmux_down_pane = function()
        tmux_or_wincmd("D", "j")
      end

      explorer.actions.tmux_up_pane = function()
        tmux_or_wincmd("U", "k")
      end

      -- This one intentionally stays inside Neovim,
      -- because from the Explorer you usually want C-l
      -- to go to the main editor buffer.
      explorer.actions.nvim_right_window = function()
        vim.cmd("wincmd l")
      end

      explorer.win = explorer.win or {}

      explorer.win.input = explorer.win.input or {}
      explorer.win.input.keys = explorer.win.input.keys or {}

      explorer.win.list = explorer.win.list or {}
      explorer.win.list.keys = explorer.win.list.keys or {}

      for _, win in ipairs({ explorer.win.input, explorer.win.list }) do
        win.keys["<c-h>"] = { "tmux_left_pane", mode = { "i", "n" } }
        win.keys["<c-j>"] = { "tmux_down_pane", mode = { "i", "n" } }
        win.keys["<c-k>"] = { "tmux_up_pane", mode = { "i", "n" } }
        win.keys["<c-l>"] = { "nvim_right_window", mode = { "i", "n" } }
      end
    end,
  },
}
