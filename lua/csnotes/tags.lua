local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Get all tags from all notes
---@return table Map of tag -> array of note paths
function M.get_all_tags()
  local notes = daily.get_all_daily_notes()
  local tag_map = {}
  
  for _, note in ipairs(notes) do
    local content, err = utils.read_file(note.path)
    if content then
      local tags = utils.extract_tags(content)
      for _, tag in ipairs(tags) do
        if not tag_map[tag] then
          tag_map[tag] = {}
        end
        table.insert(tag_map[tag], {
          path = note.path,
          filename = note.filename,
          date = note.date,
        })
      end
    end
  end
  
  return tag_map
end

--- Get notes that contain a specific tag
---@param tag string
---@return table Array of note objects
function M.get_notes_by_tag(tag)
  local tag_map = M.get_all_tags()
  return tag_map[tag] or {}
end

--- List all tags with note counts
---@return table Array of {tag: string, count: number}
function M.list_tags()
  local tag_map = M.get_all_tags()
  local tags = {}
  
  for tag, notes in pairs(tag_map) do
    table.insert(tags, {
      tag = tag,
      count = #notes,
    })
  end
  
  table.sort(tags, function(a, b)
    return a.count > b.count
  end)
  
  return tags
end

--- Display tag picker
function M.show_tag_picker()
  local tags = M.list_tags()
  
  if #tags == 0 then
    utils.info("No tags found")
    return
  end
  
  -- Create a buffer for the picker
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#tags + 2, math.floor(vim.o.lines * 0.8))
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
    title = " Tags ",
    title_pos = "center",
  })
  
  -- Populate buffer with tags
  local lines = {}
  for i, tag_info in ipairs(tags) do
    local display = string.format("%d. #%s (%d)", i, tag_info.tag, tag_info.count)
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
  
  local function select_tag()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local tag_info = tags[line]
    close_picker()
    if tag_info then
      M.show_notes_for_tag(tag_info.tag)
    end
  end
  
  -- Keybindings
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", select_tag, opts)
  vim.keymap.set("n", "<Esc>", close_picker, opts)
  vim.keymap.set("n", "q", close_picker, opts)
  vim.keymap.set("n", "<C-c>", close_picker, opts)
end

--- Show notes for a specific tag
---@param tag string
function M.show_notes_for_tag(tag)
  local notes = M.get_notes_by_tag(tag)
  
  if #notes == 0 then
    utils.info(string.format("No notes found for tag: #%s", tag))
    return
  end
  
  -- Create a buffer for the picker
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.7)
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
    title = string.format(" Notes tagged #%s ", tag),
    title_pos = "center",
  })
  
  -- Populate buffer with notes
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
    if note then
      vim.cmd("edit " .. vim.fn.fnameescape(note.path))
    end
  end
  
  -- Keybindings
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", select_note, opts)
  vim.keymap.set("n", "<Esc>", close_picker, opts)
  vim.keymap.set("n", "q", close_picker, opts)
  vim.keymap.set("n", "<C-c>", close_picker, opts)
end

return M
