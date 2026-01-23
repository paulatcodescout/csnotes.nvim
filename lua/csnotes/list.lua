local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Create a simple picker for notes
---@param notes table Array of note objects
---@param on_select function Callback when note is selected
function M.simple_picker(notes, on_select)
  if #notes == 0 then
    utils.info("No notes found")
    return
  end
  
  -- Create a buffer for the picker
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.min(#notes + 2, math.floor(vim.o.lines * 0.8))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Daily Notes ",
    title_pos = "center",
  })
  
  -- Populate buffer with note list
  local lines = {}
  for i, note in ipairs(notes) do
    local display = string.format("%d. %s", i, note.date or note.filename)
    table.insert(lines, display)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  
  -- Set up keymaps
  local function close_picker()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  local function select_note()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local note = notes[line]
    close_picker()
    if note and on_select then
      on_select(note)
    end
  end
  
  -- Keybindings
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", select_note, opts)
  vim.keymap.set("n", "<Esc>", close_picker, opts)
  vim.keymap.set("n", "q", close_picker, opts)
  vim.keymap.set("n", "<C-c>", close_picker, opts)
end

--- List all daily notes and open selected one
function M.list_daily_notes()
  local notes = daily.get_all_daily_notes()
  
  M.simple_picker(notes, function(note)
    vim.cmd("edit " .. vim.fn.fnameescape(note.path))
  end)
end

--- Display search results
---@param results table Search results
function M.display_search_results(results)
  if #results == 0 then
    utils.info("No results found")
    return
  end
  
  -- Create a buffer for results
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.min(#results + 2, math.floor(vim.o.lines * 0.9))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" Search Results (%d) ", #results),
    title_pos = "center",
  })
  
  -- Populate buffer with results
  local lines = {}
  for i, result in ipairs(results) do
    local display = string.format("%s:%d: %s", result.filename, result.line, result.content:gsub("^%s+", ""))
    table.insert(lines, display)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "csnotes-search")
  
  -- Set up keymaps
  local function close_results()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  local function open_result()
    local line_num = vim.api.nvim_win_get_cursor(win)[1]
    local result = results[line_num]
    close_results()
    if result then
      vim.cmd("edit " .. vim.fn.fnameescape(result.path))
      vim.api.nvim_win_set_cursor(0, {result.line, 0})
    end
  end
  
  -- Keybindings
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", open_result, opts)
  vim.keymap.set("n", "<Esc>", close_results, opts)
  vim.keymap.set("n", "q", close_results, opts)
  vim.keymap.set("n", "<C-c>", close_results, opts)
end

--- Prompt for search query and display results
function M.search_notes()
  vim.ui.input({ prompt = "Search notes: " }, function(query)
    if not query or query == "" then
      return
    end
    
    local results = daily.search_notes(query)
    M.display_search_results(results)
  end)
end

return M
