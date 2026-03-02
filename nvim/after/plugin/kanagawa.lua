-- Default options:
local colornames = require("kanagawa.colors").setup({theme = "dragon"})
require('kanagawa').setup({
    compile = false,             -- enable compiling the colorscheme
    undercurl = true,            -- enable undercurls
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true},
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,         -- do not set background color
    dimInactive = false,         -- dim inactive window `:h hl-NormalNC`
    terminalColors = true,       -- define vim.g.terminal_color_{0,17}
    colors = {                   -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {ui = {
			bg = colornames.palette.dragonBlack0,
			bg_gutter = "none",
			bg_visual = colornames.palette.waveBlue1
		}
		}, all = {} },
    },
    overrides = function(colors) -- add/modify highlights
        return {}
    end,
    background = {               -- map the value of 'background' option to a theme
        dark = "wave",           -- try "dragon" !
        light = "lotus"
    },
})

-- setup must be called before loading
vim.cmd("colorscheme kanagawa-dragon")
