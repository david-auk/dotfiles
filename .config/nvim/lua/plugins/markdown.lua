return {
  "yousefhadder/markdown-plus.nvim",
  ft = "markdown",

  opts = {
    -- Keep this enabled so markdown-plus still owns the smart editing
    -- mappings such as <CR>, <Tab>, <BS>, o and O.
    keymaps = {
      enabled = true,
    },

    -- We'll provide our own table mappings below.
    table = {
      keymaps = {
        enabled = false,
      },
    },
  },

  config = function(_, opts)
    require("markdown-plus").setup(opts)

    local function setup_markdown_keymaps(buf)
      if vim.b[buf].markdown_plus_custom_keymaps then
        return
      end
      vim.b[buf].markdown_plus_custom_keymaps = true

      --
      -- Remove markdown-plus command mappings, while keeping its
      -- editing/navigation mappings such as:
      --
      --   <CR>, <Tab>, <S-Tab>, <BS>
      --   o, O
      --   ]b, [b
      --   ]], [[
      --   gd
      --
      -- Insert-mode mappings are intentionally left untouched.
      --
      local keep = {
        ["o"] = true,
        ["O"] = true,
        ["]b"] = true,
        ["[b"] = true,
        ["]]"] = true,
        ["[["] = true,
        ["gd"] = true,
      }

      for _, mode in ipairs({ "n", "x" }) do
        for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
          if mapping.rhs and mapping.rhs:find("<Plug>(MarkdownPlus", 1, true) and not keep[mapping.lhs] then
            pcall(vim.keymap.del, mode, mapping.lhs, {
              buffer = buf,
            })
          end
        end
      end

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
          buffer = buf,
          silent = true,
          desc = desc,
        })
      end

      --
      -- <leader>cm = Markdown
      --

      -- Formatting
      map({ "n", "x" }, "<leader>cmb", "<Plug>(MarkdownPlusBold)", "Markdown: Bold")
      map({ "n", "x" }, "<leader>cmi", "<Plug>(MarkdownPlusItalic)", "Markdown: Italic")
      map({ "n", "x" }, "<leader>cms", "<Plug>(MarkdownPlusStrikethrough)", "Markdown: Strikethrough")
      map({ "n", "x" }, "<leader>cm`", "<Plug>(MarkdownPlusCode)", "Markdown: Inline code")
      map({ "n", "x" }, "<leader>cm=", "<Plug>(MarkdownPlusHighlight)", "Markdown: Highlight")

      -- Code blocks
      map({ "n", "x" }, "<leader>cmc", "<Plug>(MarkdownPlusCodeBlockInsert)", "Markdown: Code block")
      map("n", "<leader>cmC", "<Plug>(MarkdownPlusCodeBlockChangeLanguage)", "Markdown: Change code language")

      -- Lists
      map({ "n", "x" }, "<leader>cmx", "<Plug>(MarkdownPlusToggleCheckbox)", "Markdown: Checkbox")
      map({ "n", "x" }, "<leader>cmu", "<Plug>(MarkdownPlusToggleListUnordered)", "Markdown: Unordered list")
      map({ "n", "x" }, "<leader>cmn", "<Plug>(MarkdownPlusToggleListOrdered)", "Markdown: Ordered list")
      map({ "n", "x" }, "<leader>cmp", "<Plug>(MarkdownPlusToggleListPick)", "Markdown: Pick list type")

      -- Links
      map("n", "<leader>cml", "<Plug>(MarkdownPlusInsertLink)", "Markdown: Insert link")
      map("x", "<leader>cml", "<Plug>(MarkdownPlusSelectionToLink)", "Markdown: Selection to link")

      -- Images
      map("n", "<leader>cmI", "<Plug>(MarkdownPlusInsertImage)", "Markdown: Insert image")
      map("x", "<leader>cmI", "<Plug>(MarkdownPlusSelectionToImage)", "Markdown: Selection to image")

      -- Quotes / callouts
      map({ "n", "x" }, "<leader>cmq", "<Plug>(MarkdownPlusToggleQuote)", "Markdown: Blockquote")
      map({ "n", "x" }, "<leader>cma", "<Plug>(MarkdownPlusInsertCallout)", "Markdown: Callout")

      -- Thematic break
      map("n", "<leader>cm-", "<Plug>(MarkdownPlusInsertThematicBreak)", "Markdown: Thematic break")

      --
      -- <leader>cmh = Headings / TOC
      --

      for level = 1, 6 do
        map("n", "<leader>cmh" .. level, "<Plug>(MarkdownPlusHeader" .. level .. ")", "Markdown: Heading " .. level)
      end

      map("n", "<leader>cmh+", "<Plug>(MarkdownPlusPromoteHeader)", "Markdown: Promote heading")
      map("n", "<leader>cmh-", "<Plug>(MarkdownPlusDemoteHeader)", "Markdown: Demote heading")
      map("n", "<leader>cmhs", "<Plug>(MarkdownPlusToggleAtxSetext)", "Markdown: Toggle heading style")

      map("n", "<leader>cmht", "<Plug>(MarkdownPlusGenerateTOC)", "Markdown: Generate TOC")
      map("n", "<leader>cmhu", "<Plug>(MarkdownPlusUpdateTOC)", "Markdown: Update TOC")
      map("n", "<leader>cmho", "<Plug>(MarkdownPlusOpenTocWindow)", "Markdown: Open TOC")

      --
      -- <leader>cmt = Tables
      --

      map("n", "<leader>cmtc", "<Plug>(MarkdownPlusTableCreate)", "Markdown: Create table")
      map("n", "<leader>cmtf", "<Plug>(MarkdownPlusTableFormat)", "Markdown: Format table")
      map("n", "<leader>cmtn", "<Plug>(MarkdownPlusTableNormalize)", "Markdown: Normalize table")

      map("n", "<leader>cmtj", "<Plug>(MarkdownPlusTableMoveRowDown)", "Markdown: Move row down")
      map("n", "<leader>cmtk", "<Plug>(MarkdownPlusTableMoveRowUp)", "Markdown: Move row up")
      map("n", "<leader>cmth", "<Plug>(MarkdownPlusTableMoveColumnLeft)", "Markdown: Move column left")
      map("n", "<leader>cmtl", "<Plug>(MarkdownPlusTableMoveColumnRight)", "Markdown: Move column right")

      --
      -- <leader>cmf = Footnotes
      --

      map("n", "<leader>cmfi", "<Plug>(MarkdownPlusFootnoteInsert)", "Markdown: Insert footnote")
      map("n", "<leader>cmfe", "<Plug>(MarkdownPlusFootnoteEdit)", "Markdown: Edit footnote")
      map("n", "<leader>cmfd", "<Plug>(MarkdownPlusFootnoteDelete)", "Markdown: Delete footnote")
      map("n", "<leader>cmfn", "<Plug>(MarkdownPlusFootnoteNext)", "Markdown: Next footnote")
      map("n", "<leader>cmfp", "<Plug>(MarkdownPlusFootnotePrev)", "Markdown: Previous footnote")

      --
      -- Which-key groups
      --
      -- These groups are buffer-local, so they only appear while editing
      -- Markdown files.
      --
      -- <leader>c remains free for other "code" mappings.
      -- Markdown-specific actions live below <leader>cm.
      --
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { "<leader>cm", group = "Markdown", buffer = buf },
          { "<leader>cmh", group = "Headings / TOC", buffer = buf },
          { "<leader>cmt", group = "Tables", buffer = buf },
          { "<leader>cmf", group = "Footnotes", buffer = buf },
        })
      end
    end

    local group = vim.api.nvim_create_augroup("MarkdownPlusCustomKeymaps", {
      clear = true,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "markdown",
      callback = function(event)
        -- markdown-plus also configures mappings from FileType.
        -- Schedule ours so its mappings exist before we clean them up.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) then
            setup_markdown_keymaps(event.buf)
          end
        end)
      end,
    })

    -- The FileType event that loaded this plugin has already fired for the
    -- current buffer, so explicitly configure it once after setup().
    if vim.bo.filetype == "markdown" then
      local buf = vim.api.nvim_get_current_buf()

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          setup_markdown_keymaps(buf)
        end
      end)
    end
  end,
}
