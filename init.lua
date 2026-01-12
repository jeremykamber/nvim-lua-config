--/============================================================================
-- CORE SETTINGS
-- ============================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Performance
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
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

-- Clipboard
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

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
    priority = 1000,
    config = function()
      -- vim.cmd.colorscheme 'kanagawa'
    end,
  },

  {
    'cocopon/iceberg.vim',
    priority = 1000,
    config = function()
      -- vim.cmd.colorscheme 'iceberg'
    end,
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
      ensure_installed = { 'lua', 'python', 'javascript', 'typescript', 'dart', 'java' },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'j-hui/fidget.nvim',
    },
    config = function()
      require('mason').setup()
      require('fidget').setup {}

      require('mason-lspconfig').setup {
        ensure_installed = { 'lua_ls', 'pyright' },
      }

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')
          map('gr', require('telescope.builtin').lsp_references, 'Goto References')
          map('gI', require('telescope.builtin').lsp_implementations, 'Goto Implementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type Definition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
        end,
      })

      -- Capabilities for nvim-cmp
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      -- Auto-setup servers
      require('mason-lspconfig').setup_handlers {
        function(server_name)
          -- EXCLUDE tsserver/ts_ls because typescript-tools.nvim handles it!
          if server_name ~= 'tsserver' and server_name ~= 'ts_ls' then
            require('lspconfig')[server_name].setup { capabilities = capabilities }
          end
        end,
      }
    end,
  },

  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      -- This spawns the tsserver with a max memory of 4GB (adjust as needed)
      -- This prevents it from eating 100% of your RAM if it leaks
      tsserver_max_memory = 2048,
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
  },

  -- Completion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'L3MON4D3/LuaSnip',
      'hrsh7th/cmp-path',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'

      -- Load custom snippets
      require('luasnip.loaders.from_lua').lazy_load { paths = '~/.config/nvim/snippets' }
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          -- Confirm completion with <C-k>, select first item by default
          ['<C-k>'] = cmp.mapping.confirm { select = true },
          -- Remove <CR> as confirm key
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'copilot', group_index = 2 },
          { name = 'nvim_lsp', group_index = 2 },
          { name = 'luasnip', group_index = 2 },
          { name = 'buffer', group_index = 2 },
          { name = 'path', group_index = 2 },
        },
      }
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

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
    },
    config = function()
      require('telescope').setup {
        defaults = {
          file_ignore_patterns = { 'node_modules', '.git' },
        },
        pickers = {
          find_files = {
            find_command = { 'fd', '--type', 'f', '--color=never', '-E', '.git' },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search Help' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search Keymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search Files' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current Word' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by Grep' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search Resume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find buffers' })

      -- Your diagnostic search keymaps
      vim.keymap.set('n', '<leader>sde', function()
        builtin.diagnostics { severity = vim.diagnostic.severity.ERROR }
      end, { desc = 'Search Diagnostics: Errors' })

      vim.keymap.set('n', '<leader>sdw', function()
        builtin.diagnostics { severity = vim.diagnostic.severity.WARN }
      end, { desc = 'Search Diagnostics: Warnings' })

      vim.keymap.set('n', '<leader>sdh', function()
        builtin.diagnostics { severity = vim.diagnostic.severity.HINT }
      end, { desc = 'Search Diagnostics: Hints' })

      vim.keymap.set('n', '<leader>sda', builtin.diagnostics, { desc = 'Search Diagnostics: All' })
    end,
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

  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = {
      options = {
        theme = 'auto',
        component_separators = '|',
        section_separators = '',
      },
    },
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
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex, { desc = 'Project view' })

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
