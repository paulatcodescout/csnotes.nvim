-- Luacheck configuration
std = "luajit"
globals = {
  "vim",
}

read_globals = {
  "vim",
}

-- Ignore some pedantic warnings
ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
  "631", -- Line is too long
}

exclude_files = {
  "tests/minimal_init.lua",
}
