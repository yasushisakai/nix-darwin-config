vim.o.number = true
vim.o.scrolloff = 10
vim.o.cursorline = true
vim.o.smartcase = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 2
vim.o.foldnestmax = 4
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- if clipboard is acting weird
-- vim.schedule(function()
vim.o.clipboard = "unnamedplus"
-- end)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- LSP reltated default keymaps `:h grr`
vim.keymap.set("i", "jk", "<esc>")

local map = function(keys, func)
    vim.keymap.set("n", keys, func)
end

map("<leader><leader>", ":e #<cr>")
map("<leader>bd", "bp | bd #<cr>")
map("j", "gj")
map("k", "gk")
map("gj", "j")
map("gk", "k")

-- auto install lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end

vim.opt.rtp:prepend(lazypath)

--
require("lazy").setup({

    { "NMAC427/guess-indent.nvim", opts = {} },

    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        cmd = { "ConformInfo" },
        opts = {
            notify_on_error = false,
            formatters_by_ft = {
                -- make sure you have these in flake.nix
                lua = { "stylua" },
                nix = { "nixfmt" },
                c = { "clang-format" },
                go = { "gofmt" },
                python = { "ruff" },
                swift = { "swift" },
                markdown = { "prettierd" },
                javascript = { "prettierd" },
                typescript = { "prettierd" },
            },
            format_on_save = {
                timeout_ms = 500,
            },
        },
    },

    {
        "saghen/blink.cmp",
        dependencies = { "rafamadriz/friendly-snippets" },
        version = "1.*",
        opts = {
            completion = {
                list = {
                    selection = { preselect = false },
                },
                ghost_text = { enabled = true },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 500,
                },
            },
            keymap = {
                preset = "enter",
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
            },
            fuzzy = { implementation = "prefer_rust" },
        },
    },

    {
        "neovim/nvim-lspconfig",
        opts = {},
        config = function()
            vim.diagnostic.config({ virtual_lines = { current_line = true } })

            -- sourcekit-lsp also supports c/cpp files
            -- by default but we let "clangd" do that.
            -- This is because "clangd" also supports
            -- other filetypes like, "cuda" and "proto"
            vim.lsp.config("sourcekit", {
                filetypes = { "swift", "objc", "objcpp" },
            })

            vim.lsp.config("lua_ls", {
                -- https://luals.github.io/wiki/settings/
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = {
                            globals = { "vim", "hs" },
                        },
                        workspace = {
                            library = { vim.env.VIMRUNTIME },
                            checkThirdParty = false,
                        },
                    },
                },
            })

            vim.lsp.enable({
                "lua_ls",
                "gopls",
                "clangd",
                "sourcekit",
                -- The following LSPs for python and
                -- typescript should be configured
                -- through direnv
                "pyright",
                "ts_ls",
            })
        end,
    },

    {
        "nvim-telescope/telescope.nvim",
        event = "VimEnter",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable("make") == 1
                end,
            },
            "nvim-telescope/telescope-bibtex.nvim",
        },
        config = function()
            local ts = require("telescope")
            ts.setup({
                extensions = {
                    bibtex = {
                        global_files = { "~/Documents/memo/main.bib" },
                        context = true,
                        format = "markdown",
                    },
                },
            })

            pcall(ts.load_extension, "fzf")
            pcall(ts.load_extension, "bibtex")

            local bi = require("telescope.builtin")
            map("<leader>ff", bi.find_files)
            map("<leader>fd", bi.grep_string)
            map("<leader>fg", bi.live_grep)
            map("<leader>fq", bi.quickfix)
            map("<leader>fl", bi.loclist)
            map("<leader>fc", "<cmd>Telescope bibtex<cr>")
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")
            configs.setup({
                auto_install = true,
                highlight = { enable = true },
                indent = { enable = true },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "gsn", -- set to `false` to disable one of the mappings
                        node_incremental = "gsi",
                        scope_incremental = "gss",
                        node_decremental = "gsd",
                    },
                },
                additional_vim_regex_highlighting = false,
            })
        end,
    },
    {
        "zk-org/zk-nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("zk").setup({
                picker = "telescope",
            })

            map("<leader>zf", "<cmd>ZkNotes<cr>")
            map("<leader>zi", "<cmd>ZkInsertLink<cr>")
            map("<leader>zc", "<cmd>Telescope bibtex format_string=[@%s] <cr>")
        end,
    },

    {
        "folke/zen-mode.nvim",
        config = function()
            require("zen-mode").setup({
                window = {
                    options = {
                        number = false,
                    },
                },
                plugins = {
                    twilight = false,
                },
            })
            map("<leader>zz", function()
                vim.cmd("ZenMode")
            end)
        end,
    },

    {
        "lukas-reineke/headlines.nvim",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("headlines").setup({})
        end,
    },

    {
        "echasnovski/mini.nvim",
        config = function()
            require("mini.ai").setup({ n_lines = 500 })
            require("mini.pairs").setup()
        end,
    },

    {
        "gandor/leap.nvim",
        lazy = false,
        opts = {},
        config = function()
            require("leap").set_default_mappings()
        end,
    },
})
