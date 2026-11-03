-- Tmux navigation

vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", {
  desc = "Tmux Navigate Left",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", {
  desc = "Tmux Navigate Down",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", {
  desc = "Tmux Navigate Up",
  remap = false,
  silent = true,
})

vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", {
  desc = "Tmux Navigate Right",
  remap = false,
  silent = true,
})

-- Aliases for LazyVim's Git hunk navigation.

vim.keymap.set("n", "]g", "]h", {
  remap = true,
  silent = true,
  desc = "Next Git hunk",
})

vim.keymap.set("n", "[g", "[h", {
  remap = true,
  silent = true,
  desc = "Previous Git hunk",
})

vim.keymap.set("n", "g^", function()
  vim.cmd("normal! 0")
  vim.fn.search([[\k]], "cW", vim.fn.line("."))
end, {
  desc = "Go to first keyword character of line",
})

-- Line navigation

-- Position the cursor and enter Insert mode after the mapping.
local function enter_insert(bufnr, row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })

  vim.schedule(function()
    if vim.api.nvim_get_current_buf() == bufnr then
      vim.cmd("startinsert")
    end
  end)
end

-- Open counted lines while preserving indentation.
local function open_lines(above)
  local count = vim.v.count1
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local insert_at = above and row - 1 or row

  -- Inherit indentation from the current line.
  local indent = ""
  if vim.bo.autoindent then
    indent = vim.api.nvim_get_current_line():match("^%s*") or ""
  end

  -- Create all requested lines immediately.
  local lines = {}
  for i = 1, count do
    lines[i] = indent
  end

  vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, lines)

  -- o: last new line; O: first new line.
  local target = above and insert_at + 1 or insert_at + count

  enter_insert(bufnr, target, #indent)
end

vim.keymap.set("n", "o", function()
  open_lines(false)
end, {
  silent = true,
  desc = "Open lines below",
})

vim.keymap.set("n", "O", function()
  open_lines(true)
end, {
  silent = true,
  desc = "Open lines above",
})

-- Spaced line navigation

-- Open an editing line with blank lines above and below.
-- Existing blank lines are reused whenever possible.
local function open_spaced_line(above)
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Determine the editing line's position.
  local target = above and row - 1 or row + 1

  -- Check for an empty or whitespace-only line.
  local function is_blank(line)
    if line < 1 or line > vim.api.nvim_buf_line_count(bufnr) then
      return false
    end

    local content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]

    return content:match("^%s*$") ~= nil
  end

  -- Reuse an adjacent blank line, or create a new one.
  if target < 1 or target > line_count or not is_blank(target) then
    local insert_at = above and row - 1 or row

    vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, { "" })

    target = insert_at + 1
  end

  -- Ensure an empty line above.
  if not is_blank(target - 1) then
    vim.api.nvim_buf_set_lines(bufnr, target - 1, target - 1, false, { "" })

    target = target + 1
  end

  -- Ensure an empty line below.
  if not is_blank(target + 1) then
    vim.api.nvim_buf_set_lines(bufnr, target, target, false, { "" })
  end

  enter_insert(bufnr, target, 0)
end

vim.keymap.set("n", "<leader>o", function()
  open_spaced_line(false)
end, {
  silent = true,
  desc = "Open spaced line below",
})

vim.keymap.set("n", "<leader>O", function()
  open_spaced_line(true)
end, {
  silent = true,
  desc = "Open spaced line above",
})
