return {
  {
    dir = vim.fn.stdpath("config") .. "/dracula_pro",
    name = "dracula_pro",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.dracula_colorterm = 0
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula_pro",
    },
  },
}
