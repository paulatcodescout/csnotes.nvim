-- Minimal init file for running tests
-- This sets up the test environment

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"

-- Download plenary if it doesn't exist
if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_dir,
  })
end

-- Add plenary and current plugin to runtimepath
vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append(plenary_dir)

-- Set up required paths
vim.cmd("runtime plugin/plenary.vim")

-- Ensure the plugin is loaded
require("plenary.busted")
