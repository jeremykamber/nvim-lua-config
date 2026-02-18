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
vim.opt.cursorline = false -- Disabled for performance on slower terminals
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

local float_state = {
  last_win = nil,
  offset_x = 2, -- How much to shift right each time
  offset_y = 2, -- How much to shift down each time
}

local function get_tiled_position()
  local width = math.floor(vim.o.columns * 0.4) -- 40% width for tiling
  local height = math.floor(vim.o.lines * 0.5) -- 50% height

  -- Check if the last window still exists and is valid
  if float_state.last_win and vim.api.nvim_win_is_valid(float_state.last_win) then
    local config = vim.api.nvim_win_get_config(float_state.last_win)
    local new_col = config.col + float_state.offset_x
    local new_row = config.row + float_state.offset_y

    -- Reset to center if we drift too far off screen
    if new_col + width > vim.o.columns or new_row + height > vim.o.lines then
      return { width = width, height = height } -- Defaults to center
    end

    return { width = width, height = height, col = new_col, row = new_row, relative = 'editor' }
  end

  return { width = width, height = height } -- Default center for first window
end

local function search_windows()
  local fzf = require 'fzf-lua'
  local wins = vim.api.nvim_list_wins()
  local items = {}

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    local filename = name ~= '' and vim.fn.fnamemodify(name, ':t') or '[No Name]'

    -- Format: "WindowID: Filename (Path)"
    table.insert(items, string.format('%d: %s (%s)', win, filename, name))
  end

  fzf.fzf_exec(items, {
    actions = {
      ['default'] = function(selected)
        local win_id = tonumber(selected[1]:match '^(%d+):')
        vim.api.nvim_set_current_win(win_id)
      end,
    },
    winopts = { title = ' Search Windows ', height = 0.3, width = 0.5 },
  })
end

require('lazy').setup({
  -- Colorscheme

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

  -- Swift Development

  {
    'wojciech-kulik/xcodebuild.nvim',
    dependencies = {
      -- Uncomment a picker that you want to use, snacks.nvim might be additionally
      -- useful to show previews and failing snapshots.

      -- You must select at least one:
      -- "nvim-telescope/telescope.nvim",
      'ibhagwan/fzf-lua',
      -- "folke/snacks.nvim", -- (optional) to show previews

      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-tree.lua', -- (optional) to manage project files
      'stevearc/oil.nvim', -- (optional) to manage project files
      'nvim-treesitter/nvim-treesitter', -- (optional) for Quick tests support (required Swift parser)
    },
    config = function()
      require('xcodebuild').setup {
        -- put some options here or leave it empty to use default settings
      }
    end,
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter.configs',
    opts = {
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>', -- Enter to start selecting
          node_incremental = '<CR>', -- Enter to expand selection (function -> class)
          scope_incremental = false,
          node_decremental = '<bs>', -- Backspace to shrink
        },
      },
      nsure_installed = { 'lua', 'python', 'javascript', 'typescript', 'tsx', 'css', 'html', 'swift' },
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

  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      win = {
        -- Optional: customize the default floating window style
        style = 'float',
      },
    },
  },

  -- Fun stuff

  {
    'rmagatti/goto-preview',
    dependencies = { 'rmagatti/logger.nvim' },
    event = 'BufEnter',
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    opts = {
      references = {
        provider = 'fzf_lua',
      },
      default_mappings = true,
    },
  },

  {
    'vim-test/vim-test',
    cmd = { 'TestFile', 'TestNearest', 'TestSuite', 'TestLast', 'TestVisit' },
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'j-hui/fidget.nvim',
      { 'yioneko/nvim-vtsls' },
    },
    config = function()
      require('mason').setup()
      require('fidget').setup {}

      local mlsp = require 'mason-lspconfig'
      mlsp.setup {
        ensure_installed = { 'lua_ls', 'pyright', 'vtsls', 'biome' },
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Optimize for blink.cmp: try to require the module so capabilities are augmented
      local ok, blink_cmp = pcall(require, 'blink.cmp')
      if ok and type(blink_cmp.get_lsp_capabilities) == 'function' then
        capabilities = blink_cmp.get_lsp_capabilities(capabilities)
      end

      -- LSP keymaps on attach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end
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
          map('<leader>ss', fzf.lsp_live_workspace_symbols, 'Search Symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', fzf.lsp_code_actions, 'Code Action')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
          if client.name == 'vtsls' then
            vim.keymap.set('n', '<leader>co', '<cmd>VtslsCommand source.organizeImports<cr>', { buffer = event.buf, desc = '[O]rganize Imports' })
            vim.keymap.set('n', '<leader>cm', '<cmd>VtslsCommand source.addMissingImports<cr>', { buffer = event.buf, desc = 'Add [M]issing Imports' })
          end
        end,
      })

      -- Servers setup
      local servers = {
        sourcekit = {
          cmd = { 'xcrun', 'sourcekit-lsp' },
          filetypes = { 'swift', 'objective-c', 'objective-cpp' },
          root_dir = require('lspconfig').util.root_pattern('Package.swift', '.git', 'buildServer.json'),
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        vtsls = {
          settings = {
            typescript = {
              tsserver = {
                maxTsServerMemory = 1024, -- Hard cap at 1GB
              },
              -- -- ONLY check open files to save RAM
              -- reportStyleChecksAsWarnings = false,
              diagnostics = { ignoredCodes = { 80001, 80006 } }, -- Filter out noise
            },
            vtsls = {
              autoUseWorkspaceTsdk = true,
              -- Experimental features for speed
              experimental = { completion = { enableServerSideFuzzyMatch = true } },
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
            -- list of servers to IGNORE because they are handled elsewhere or too heavy
            if server_name == 'tsserver' or server_name == 'ts_ls' then
              return
            end
            local config = servers[server_name] or {}
            config.capabilities = capabilities
            require('lspconfig')[server_name].setup(config)
          end,
          ['sourcekit'] = function()
            require('lspconfig').sourcekit.setup(servers.sourcekit)
          end,
        }
      end
    end,
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
    opts = {
      notifications = true, -- Useful to see when it's working; set to false later
      grace_period = 300, -- 5 minutes of inactivity triggers the "garbage collection"
      wakeup_delay = 0, -- Wake up the LSP immediately when you enter the buffer
      -- Ensure it targets the heavy hitters
      excluded_lsp_clients = {
        'copilot', -- Keep Copilot alive as it's low RAM
      },
    },
  },

  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'rafamadriz/friendly-snippets' },
    lazy = true,
  },

  -- Completion (Rust-powered for speed and low RAM)
  {
    'saghen/blink.cmp',
    lazy = false,
    dependencies = { 'rafamadriz/friendly-snippets', 'L3MON4D3/LuaSnip' },
    version = '*',
    event = 'InsertEnter',
    opts = {
      cmdline = { sources = { 'cmdline' } },
      snippets = {
        preset = 'luasnip',
        expand = function(snippet)
          require('luasnip').lsp_expand(snippet)
        end,
        active = function(filter)
          return require('luasnip').locally_jumpable()
        end,
        jump = function(direction)
          require('luasnip').jump(direction)
        end,
      },
      keymap = {
        preset = 'default',
        ['<C-k>'] = { 'select_and_accept', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
        per_filetype = {
          codecompanion = { 'codecompanion' },
        },
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
      'ibhagwan/fzf-lua',
    },
    opts = {
      adapters = {
        copilot = function()
          return require('codecompanion.adapters').extend('copilot', {
            schema = {
              model = {
                default = 'gpt-5-mini',
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
      { '<leader>sGc', '<cmd>FzfLua git_commits<cr>', desc = 'Search Git Commits' },
      { '<leader>sGd', '<cmd>FzfLua git_diff<cr>', desc = 'Search Git Diff' },
      { '<leader>sGb', '<cmd>FzfLua git_branches<cr>', desc = 'Search Git Branches' },
      { '<leader>sGs', '<cmd>FzfLua git_status<cr>', desc = 'Search Git Status' },
      { '<leader><leader>', '<cmd>FzfLua buffers<cr>', desc = 'Find buffers' },
      { '<leader>sh', '<cmd>FzfLua help_tags<cr>', desc = 'Search Help' },
      { '<leader>sk', '<cmd>FzfLua keymaps<cr>', desc = 'Search Keymaps' },
      { '<leader>sr', '<cmd>FzfLua resume<cr>', desc = 'Search Resume' },
      { '<leader>s.', '<cmd>FzfLua oldfiles<cr>', desc = 'Search Recent Files' },
      { '<leader>sDa', '<cmd>FzfLua diagnostics_document<cr>', desc = 'Search Document Diagnostics' },
      { '<leader>sda', '<cmd>FzfLua diagnostics_workspace<cr>', desc = 'Search Workspace Diagnostics' },
      { '<leader>sf', '<cmd>FzfLua files<cr>', desc = 'Search Files' },
      { '<leader>sg', '<cmd>FzfLua live_grep<cr>', desc = 'Search by Grep' },
      { '<leader><leader>', '<cmd>FzfLua buffers<cr>', desc = 'Find buffers' },
      { '<leader>sh', '<cmd>FzfLua help_tags<cr>', desc = 'Search Help' },
      { '<leader>sk', '<cmd>FzfLua keymaps<cr>', desc = 'Search Keymaps' },
      { '<leader>sr', '<cmd>FzfLua resume<cr>', desc = 'Search Resume' },
      { '<leader>s.', '<cmd>FzfLua oldfiles<cr>', desc = 'Search Recent Files' },

      -- All Diagnostics (Document/Workspace)
      { '<leader>sDa', '<cmd>FzfLua diagnostics_document<cr>', desc = 'Search Doc Diagnostics' },
      { '<leader>sda', '<cmd>FzfLua diagnostics_workspace<cr>', desc = 'Search Project Diagnostics' },

      -- ERRORS (sde = all errors, sDe = current file errors)
      { '<leader>sde', '<cmd>FzfLua diagnostics_workspace severity=error<cr>', desc = 'Search Project Errors' },
      { '<leader>sDe', '<cmd>FzfLua diagnostics_document severity=error<cr>', desc = 'Search Doc Errors' },

      -- WARNINGS (sdw = all warnings, sDw = current file warnings)
      { '<leader>sdw', '<cmd>FzfLua diagnostics_workspace severity=warning<cr>', desc = 'Search Project Warnings' },
      { '<leader>sDw', '<cmd>FzfLua diagnostics_document severity=warning<cr>', desc = 'Search Doc Warnings' },
    },
    opts = function()
      local fzf = require 'fzf-lua'

      -- Custom function to open file in a Snacks float

      local open_in_snacks_float = function(selected)
        if not selected or #selected == 0 then
          return
        end
        local file = require('fzf-lua').path.entry_to_file(selected[1]).path
        local pos = get_tiled_position()

        local win = require('snacks').win {
          file = file,
          width = pos.width,
          height = pos.height,
          col = pos.col,
          row = pos.row,
          relative = pos.relative or 'editor',
          -- --- STYLING START ---
          border = 'rounded',
          title = ' ' .. vim.fn.fnamemodify(file, ':t') .. ' ', -- Filename as title
          title_pos = 'center',
          backdrop = 100,
          wo = {
            winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle',
            cursorline = true, -- Highlight current line in the float
          },
          -- --- STYLING END ---
        }

        float_state.last_win = win.win
      end
      return {
        keymap = {
          fzf = {
            ['ctrl-d'] = 'preview-page-down',
            ['ctrl-u'] = 'preview-page-up',
          },
          builtin = {
            ['<C-d>'] = 'preview-page-down',
            ['<C-u>'] = 'preview-page-up',
          },
        },
        -- Add the custom action to all file/buffer pickers
        actions = {
          files = {
            ['default'] = fzf.actions.file_edit,
            ['ctrl-o'] = open_in_snacks_float, -- Bind to Ctrl-f
            ['ctrl-q'] = fzf.actions.files_to_qf,
          },
          buffers = {
            ['default'] = fzf.actions.buf_edit,
            ['ctrl-o'] = open_in_snacks_float,
          },
        },
        winopts = {
          preview = {
            hidden = 'nohidden',
            vertical = 'down:45%',
            layout = 'vertical',
          },
        },
      }
    end,
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
        javascript = { 'biome' },
        typescript = { 'biome' },
        swift = { 'swiftformat' },
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
-- *KEYMAPS*
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
vim.keymap.set('n', '-', '<cmd>b#<CR>', { desc = 'Switch to last buffer' })

-- Config shortcuts
vim.keymap.set('n', '<leader>so', '<cmd>source ~/.config/nvim/init.lua<CR>', { desc = 'Source config' })
vim.keymap.set('n', '<leader>i', '<cmd>e ~/.config/nvim/init.lua<CR>', { desc = 'Edit init.lua' })

-- File/write shortcuts
vim.keymap.set('n', '<leader>wf', '<cmd>w<CR>', { desc = 'Write File' })
-- <leader>pv is handled by oil.nvim now

-- Floating windows
vim.keymap.set('n', '<leader>sw', search_windows, { desc = 'Search Open Windows' })

-- Pop current buffer into a floating window
vim.keymap.set('n', '<leader>o', function()
  local pos = get_tiled_position()
  local win = require('snacks').win {
    buf = vim.api.nvim_get_current_buf(),
    width = pos.width,
    height = pos.height,
    col = pos.col,
    row = pos.row,
    relative = pos.relative or 'editor',
  }
  float_state.last_win = win.win
end, { desc = 'Float current buffer (Tiled)' })

-- Add these to your KEYMAPS section
local function goto_next_error()
  vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
end

local function goto_prev_error()
  vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
end

-- Keybinds for jumping specifically to errors
vim.keymap.set('n', ']e', goto_next_error, { desc = 'Next Error' })
vim.keymap.set('n', '[e', goto_prev_error, { desc = 'Prev Error' })

-- Quickfix navigation (to cycle through fzf-lua results sent via Alt-q)
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zz', { desc = 'Next Quickfix Item' })
vim.keymap.set('n', '[q', '<cmd>cprev<cr>zz', { desc = 'Prev Quickfix Item' })

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
  vim.api.nvim_feedkeys(':CodeCompanion #{buffer} ', 'n', false)
end, { desc = 'AI Inline (all, prompt editable)' })
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

local float_dim_group = vim.api.nvim_create_augroup('FloatDimming', { clear = true })

vim.api.nvim_create_autocmd({ 'WinEnter', 'WinLeave' }, {
  group = float_dim_group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(win)

    -- Check if current window is a floating window
    if config.relative ~= '' then
      if ev.event == 'WinEnter' then
        -- Brighten and highlight border when focused
        vim.wo[win].winblend = 0
        vim.api.nvim_set_hl(0, 'SnacksBackdrop', { bg = '#000000', blend = 80 }) -- Dim background more
      else
        -- Dim the window when leaving
        vim.wo[win].winblend = 20
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ 'WinEnter', 'WinLeave' }, {
  group = float_dim_group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    local config = vim.api.nvim_win_get_config(win)

    if config.relative ~= '' then
      if ev.event == 'WinEnter' then
        vim.wo[win].winblend = 0
        -- Active border color (Blue)
        vim.api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:FloatBorder,Normal:NormalFloat')
      else
        vim.wo[win].winblend = 20
        -- Dimmed border color (Grey/Muted)
        vim.api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:Comment,Normal:NormalFloat')
      end
    end
  end,
})

-- Custom highlights for floating windows
vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#7aa2f7' }) -- Match TokyoNight blue
vim.api.nvim_set_hl(0, 'FloatTitle', { fg = '#bb9af7', bold = true }) -- Purple title
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#1a1b26' }) -- Deep background
