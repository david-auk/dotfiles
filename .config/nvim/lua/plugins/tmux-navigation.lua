return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    config = function()
      local ok, wrapper = pcall(require, "tmux.wrapper.nvim")
      if not ok then
        return
      end

      wrapper.is_nvim_float = function()
        local snacks_ok, snacks = pcall(function()
          return Snacks
        end)

        if snacks_ok and snacks and snacks.picker then
          local is_explorer = vim.iter(snacks.picker.get({ source = "explorer" })):any(function(picker)
            return picker:is_focused()
          end)

          if is_explorer then
            return false
          end
        end

        return vim.api.nvim_win_get_config(0).relative ~= ""
      end
    end,
  },
}
