--/============================================================================
-- CORE SETTINGS
-- ============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Performance
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10
vim.opt.shada = "!,'100,<50,s10,h" -- Limit shada size for faster startup

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = false  -- Disabled for performance on slower terminals
vim.opt.termguicolors = true
vim.opt.scrolloff = 10

-- Editing
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.undofile = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.inccommand = 'split'

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Clipboard (only use system clipboard with explicit keymaps, not every delete)
-- vim.schedule(function()
--   vim.opt.clipboard = 'unnamedplus'
-- end)

-- ============================================================================
-- LAZY.NVIM BOOTSTRAP
-- ============================================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGINS
-- ============================================================================
require('lazy').setup({
  -- Colorscheme

  {
    'vim-test/vim-test',
    cmd = { 'TestFile', 'TestNearest', 'TestSuite', 'TestLast', 'TestVisit' },
  },

  {
    'rebelot/kanagawa.nvim',
    enabled = false,
  },

  {
    'cocopon/iceberg.vim',
    enabled = false,
  },

  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'lua', 'python', 'javascript', 'typescript', 'tsx', 'css', 'html' },
      auto_install = false,
      highlight = {
        enable = true,
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },
      indent = { enable = true },
    },
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'j-hui/fidget.nvim',
    },
    config = function()
      require('mason').setup()
      require('fidget').setup {}

      local mlsp = require 'mason-lspconfig'
      mlsp.setup {
        ensure_installed = { 'lua_ls', 'pyright' },
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Optimize for blink.cmp
      if package.loaded['blink.cmp'] then
        capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
      end

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Using fzf-lua for LSP lookups (faster than telescope)
          local fzf = require 'fzf-lua'
          map('gd', fzf.lsp_definitions, 'Goto Definition')
          map('gr', fzf.lsp_references, 'Goto References')
          map('gI', fzf.lsp_implementations, 'Goto Implementation')
          map('<leader>D', fzf.lsp_typedefs, 'Type Definition')
          map('<leader>ds', fzf.lsp_document_symbols, 'Document Symbols')
          map('<leader>ws', fzf.lsp_live_workspace_symbols, 'Workspace Symbols')

          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
        end,
      })

      -- Servers setup
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = 'openFilesOnly', -- Significant memory saver
              },
            },
          },
        },
      }

      if mlsp.setup_handlers then
        mlsp.setup_handlers {
          function(server_name)
            if server_name == 'tsserver' or server_name == 'ts_ls' then return end
            local config = servers[server_name] or {}
            config.capabilities = capabilities
            require('lspconfig')[server_name].setup(config)
          end,
        }
      end
    end,
  },

  {
    'pmizio/typescript-tools.nvim',
    ft = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      tsserver_max_memory = 1536, -- Reduced for more aggressive memory management
      separate_diagnostic_server = true, -- Better UI responsiveness
      publish_diagnostic_on = 'insert_leave', -- Reduces overhead
      expose_as_code_action = 'all',
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'none', -- Performance
          includeInlayVariableTypeHints = false,
        },
      },
    },
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'zeioth/garbage-day.nvim',
    dependencies = 'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
    lazy = true,
  },

  -- Completion (Rust-powered for speed and low RAM)
  {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets', 'L3MON4D3/LuaSnip' },
    version = '*',
    event = 'InsertEnter',
    opts = {
      snippets = {
        preset = 'luasnip',
        expand = function(snippet) require('luasnip').lsp_expand(snippet) end,
        active = function(filter) return require('luasnip').locally_jumpable() end,
        jump = function(direction) require('luasnip').jump(direction) end,
      },
      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'accept', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      completion = {
        list = { selection = { preselect = false, auto_insert = true } },
        menu = { auto_show = true },
        ghost_text = { enabled = true },
      },
    },
    config = function(_, opts)
      require('luasnip.loaders.from_vscode').lazy_load()
      require('blink.cmp').setup(opts)
    end,
  },

  -- Copilot
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
        },
        panel = { enabled = false },
      }

      -- Accept Copilot suggestion with <C-j> in insert mode
      vim.keymap.set('i', '<C-j>', function()
        return require('copilot.suggestion').accept()
      end, { expr = true, desc = 'Copilot Accept Suggestion' })
    end,
  },

  -- CodeCompanion
  {
    'olimorris/codecompanion.nvim',
    cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      adapters = {
        copilot = function()
          return require('codecompanion.adapters').extend('copilot', {
            schema = {
              model = {
                default = 'gpt-4.1', -- Use exact Copilot model ID (verify in Copilot Chat)
              },
            },
          })
        end,
      },
      strategies = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
      },
    },
  },

  -- fzf-lua (Lightning fast alternative to Telescope)
  {
    'ibhagwan/fzf-lua',
    cmd = 'FzfLua',
    keys = {
      { '<leader>sf', '<cmd>FzfLua files<cr>', desc = 'Search Files' },
      { '<leader>sg', '<cmd>FzfLua live_grep<cr>', desc = 'Search by Grep' },
      { '<leader>sw', '<cmd>FzfLua grep_cword<cr>', desc = 'Search current Word' },
      { '<leader><leader>', '<cmd>FzfLua buffers<cr>', desc = 'Find buffers' },
      { '<leader>sh', '<cmd>FzfLua help_tags<cr>', desc = 'Search Help' },
      { '<leader>sk', '<cmd>FzfLua keymaps<cr>', desc = 'Search Keymaps' },
      { '<leader>sr', '<cmd>FzfLua resume<cr>', desc = 'Search Resume' },
      { '<leader>s.', '<cmd>FzfLua oldfiles<cr>', desc = 'Search Recent Files' },
      { '<leader>sd', '<cmd>FzfLua diagnostics_document<cr>', desc = 'Search Document Diagnostics' },
      { '<leader>sD', '<cmd>FzfLua diagnostics_workspace<cr>', desc = 'Search Workspace Diagnostics' },
    },
    opts = {
      keymap = {
        fzf = {
          ['ctrl-d'] = 'preview-page-down',
          ['ctrl-u'] = 'preview-page-up',
        },
      },
      winopts = {
        preview = {
          hidden = 'nohidden',
          vertical = 'down:45%',
          layout = 'vertical',
        },
      },
    },
  },

  -- oil.nvim (Fast file exploration)
  {
    'stevearc/oil.nvim',
    opts = {},
    keys = {
      { '<leader>pv', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },

  -- Harpoon
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():add()
      end)
      vim.keymap.set('n', '<C-e>', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
      vim.keymap.set('n', '<leader>1', function()
        harpoon:list():select(1)
      end)
      vim.keymap.set('n', '<leader>2', function()
        harpoon:list():select(2)
      end)
      vim.keymap.set('n', '<leader>3', function()
        harpoon:list():select(3)
      end)
      vim.keymap.set('n', '<leader>4', function()
        harpoon:list():select(4)
      end)
      vim.keymap.set('n', '<leader>5', function()
        harpoon:list():select(5)
      end)
    end,
  },

  -- Codi.nvim (code scratchpad)
  {
    'metakirby5/codi.vim',
    cmd = { 'Codi', 'CodiNew', 'CodiExpand' },
  },

  -- Conform (formatting)
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
      },
    },
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
  },

  -- Comment
  {
    'numToStr/Comment.nvim',
    keys = { 'gc', 'gb' },
    config = true,
  },

  -- Surround
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    config = true,
  },

  -- Git
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'G' },
  },

  -- Status line (Replaced with lighter alternative)
  {
    'echasnovski/mini.statusline',
    event = 'VeryLazy',
    version = false,
    config = function()
      require('mini.statusline').setup()
    end,
  },

  -- Which-key
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      delay = 0,
      spec = {
        { '<leader>a', group = 'AI', mode = { 'n', 'x' } },
        { '<leader>c', group = 'Code', mode = { 'n', 'x' } },
        { '<leader>d', group = 'Document/Diagnostics' },
        { '<leader>r', group = 'Rename' },
        { '<leader>s', group = 'Search' },
        { '<leader>w', group = 'Workspace' },
      },
    },
  },
}, {
  performance = {
    cache = { enabled = true },
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Clear search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Code Actions

vim.api.nvim_set_keymap('n', '<leader>q', ':lua vim.diagnostic.setloclist()<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>.', ':lua vim.lsp.buf.code_action()<CR>', { desc = 'Code Action' })

-- Buffer management
vim.keymap.set('n', '<leader>bd', '<cmd>bnext<CR><cmd>bd#<CR>', { desc = 'Close buffer' })
vim.keymap.set('n', '<Tab>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })

-- Config shortcuts
vim.keymap.set('n', '<leader>so', '<cmd>source ~/.config/nvim/init.lua<CR>', { desc = 'Source config' })
vim.keymap.set('n', '<leader>i', '<cmd>e ~/.config/nvim/init.lua<CR>', { desc = 'Edit init.lua' })

-- File/write shortcuts
vim.keymap.set('n', '<leader>wf', '<cmd>w<CR>', { desc = 'Write File' })
-- <leader>pv is handled by oil.nvim now

-- Terminal
vim.keymap.set('n', '<leader>wt', '<cmd>12sp | term<CR>', { desc = 'Open terminal' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Codi scratchpad
vim.keymap.set('n', '<leader>cc', '<cmd>Codi<CR>', { desc = 'Codi scratchpad' })

-- Your AI keybinds
vim.keymap.set('n', '<leader>aa', '<cmd>CodeCompanionActions<CR>', { desc = 'AI Actions' })
vim.keymap.set('n', '<leader>ail', ':CodeCompanion #{buffer} ', { desc = 'AI Inline (line)' })
vim.keymap.set('n', '<leader>aia', function()
  vim.cmd 'normal! ggVG'
  vim.cmd 'CodeCompanion #{buffer}'
end, { desc = 'AI Inline (all)' })
vim.keymap.set('v', '<leader>ai', ':CodeCompanion #{buffer} ', { desc = 'AI Inline (visual)' })
vim.keymap.set('n', '<leader>ao', '<cmd>CodeCompanionChat<CR>', { desc = 'AI Chat' })
vim.keymap.set('n', '<leader>ad', '<cmd>CodeCompanion /docs<CR>', { desc = 'AI Documentation' })
vim.keymap.set('n', '<leader>ac', '<cmd>CodeCompanion /commit<CR>', { desc = 'AI Commit' })
vim.keymap.set('n', '<leader>af', '<cmd>CodeCompanion /fix<CR>', { desc = 'AI Fix' })
vim.keymap.set('n', '<leader>at', '<cmd>CodeCompanion /tests<CR>', { desc = 'AI Tests' })
vim.keymap.set('n', '<leader>at', '<cmd>CodeCompanion /tests<CR>', { desc = 'AI Tests' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move left' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move right' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move up' })

-- Move lines in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

-- Keep cursor centered
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Paste without losing register
vim.keymap.set('x', '<leader>p', '"_dP')

-- System clipboard
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')

-- Delete to void register
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d')

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

-- Fast terminal exit
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd 'startinsert'
  end,
})

-- Large File Optimization
local bigfile_group = vim.api.nvim_create_augroup('BigFile', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPre', 'FileReadPre' }, {
  group = bigfile_group,
  callback = function(ev)
    local size = vim.fn.getfsize(ev.file)
    if size > 1024 * 1024 then -- > 1MB
      vim.b.bigfile = true
      vim.opt_local.spell = false
      vim.opt_local.undofile = false
      vim.opt_local.breakindent = false
      vim.opt_local.loadplugins = false
      vim.opt_local.syntax = 'off'
    end
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Fix CSS autopair asterisk issue
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'css', 'scss', 'less' },
  callback = function()
    vim.opt_local.formatoptions:remove { 'r', 'o' }
  end,
})

-- Diagnostic configuration
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = true,
  virtual_text = {
    source = 'if_many',
    spacing = 2,
  },
}
