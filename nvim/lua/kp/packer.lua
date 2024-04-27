-- this file can be loaded by calling `lua require('plugins')` from your init.vim

-- only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup({
function(use)
  -- packer can manage itself
  use 'wbthomason/packer.nvim'
  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.5',
	  -- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
  }
  use "rebelot/kanagawa.nvim"
  use {
	  'nvim-treesitter/nvim-treesitter',
	  run = ':tsupdate'
  }
  use('nvim-treesitter/playground')
  use('preservim/nerdcommenter')
  
  use('lervag/vimtex')
end,
config = {
	clone_timeout = 120
}
})

