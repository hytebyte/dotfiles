return require('packer').startup(function(use, use_rocks)
  -- Make packer manage itself.
  use { 'wbthomason/packer.nvim' }

  -- Collection of configurations for the built-in LSP client.
  use { 'neovim/nvim-lspconfig' }

  use { 'hrsh7th/nvim-cmp' }

  use { 'L3MON4D3/LuaSnip' }
  use { 'saadparwaiz1/cmp_luasnip' }

  use { 'hrsh7th/cmp-nvim-lsp' }
  use { 'hrsh7th/cmp-buffer' }
  use { 'hrsh7th/cmp-path' }

  use { 'tpope/vim-sensible' }
  use { 'tpope/vim-surround' }
  use { 'tpope/vim-unimpaired' }
  use { 'tpope/vim-vinegar' }
  use { 'christoomey/vim-tmux-navigator' }
  use { 'ctrlpvim/ctrlp.vim' }
  use { 'vim-scripts/matchit.zip' }

  use { 'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('indent_blankline').setup {
        char = '\u{2506}',
        show_trailing_blankline_indent = false,
      }
    end,
  }

  use { 'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  }

  -- Color schemes.
  use { 'morhetz/gruvbox' }
  use { 'w0ng/vim-hybrid' }
  use { 'overcache/NeoSolarized' }

  -- Lightline.
  use { 'itchyny/lightline.vim' }
  use { 'shinchu/lightline-gruvbox.vim' }

  -- Fugitive.
  use { 'tpope/vim-fugitive' }
  use { 'shumphrey/fugitive-gitlab.vim' }
  use { 'tpope/vim-rhubarb' }

  -- Used for OSC 52.
  use_rocks { 'base64' }
end)
