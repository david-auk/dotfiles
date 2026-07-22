local spell_directory = vim.fn.stdpath("config") .. "/spell"
local spell_file = spell_directory .. "/personal.utf-8.add"
local ltex_directory = spell_directory .. "/ltex"

local prose_filetypes = {
  "markdown",
  "text",
  "gitcommit",
  "tex",
  "plaintex",
}

return {
  -- Native Neovim spelling.
  --
  -- Dutch and English words are accepted simultaneously.
  -- Words added with `zg` are persisted in:
  --   spell/personal.utf-8.add
  {
    "LazyVim/LazyVim",

    init = function()
      vim.fn.mkdir(spell_directory, "p")
      vim.fn.mkdir(ltex_directory, "p")

      local group = vim.api.nvim_create_augroup("ProseSpelling", {
        clear = true,
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = prose_filetypes,

        callback = function()
          vim.opt_local.spell = true

          -- Accept Dutch and English words.
          vim.opt_local.spelllang = {
            "nl",
            "en_us",
          }

          -- Store words added using `zg` in this file.
          vim.opt_local.spellfile = spell_file

          -- Check the individual components of camelCase and PascalCase words.
          vim.opt_local.spelloptions:append("camel")
        end,

        desc = "Enable Dutch and English spelling in prose files",
      })
    end,

    keys = {
      {
        "z=",
        function()
          require("telescope.builtin").spell_suggest()
        end,
        desc = "Spelling suggestions",
      },
    },
  },

  -- Implements and persists LTeX code actions such as:
  --   Add to dictionary
  --   Disable rule
  --   Hide false positive
  {
    "barreiroleo/ltex_extra.nvim",
    ft = prose_filetypes,
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },

  -- Install LTeX+ through Mason.
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ltex-ls-plus",
      },
    },
  },

  -- LTeX+ handles grammar and writing style.
  --
  -- Native Neovim spelling handles bilingual spelling, so LTeX's
  -- MORFOLOGIK spelling rules are disabled.
  {
    "neovim/nvim-lspconfig",

    opts = {
      servers = {
        -- Prevent an installed legacy ltex-ls package from being
        -- automatically enabled by Mason/LazyVim.
        ltex = {
          enabled = false,
          mason = false,
        },

        ltex_plus = {
          cmd = {
            "ltex-ls-plus",
          },

          filetypes = prose_filetypes,

          settings = {
            ltex = {
              -- Use Dutch grammar by default.
              language = "nl-NL",

              checkFrequency = "edit",

              additionalRules = {
                enablePickyRules = true,
              },

              -- Spelling is handled by Neovim using `spelllang`.
              -- LTeX+ remains responsible for grammar and style.
              disabledRules = {
                ["nl-NL"] = {
                  "MORFOLOGIK_RULE_NL_NL",
                },

                ["en-US"] = {
                  "MORFOLOGIK_RULE_EN_US",
                },
              },
            },
          },

          on_attach = function()
            -- Do not provide `server_opts` here.
            -- LazyVim already started and attached ltex_plus.
            require("ltex_extra").setup({
              load_langs = {
                "nl-NL",
                "en-US",
              },

              init_check = true,
              path = ltex_directory,
              log_level = "none",
            })
          end,
        },
      },
    },
  },
}
