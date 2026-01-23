local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Archive a single note
---@param note_path string
---@return boolean success
---@return string|nil error
function M.archive_note(note_path)
  local archive_dir = utils.expand_path(config.get("archive_dir"))
  local ok, err = utils.mkdir_p(archive_dir)
  if not ok then
    return false, "Failed to create archive directory: " .. (err or "unknown error")
  end
  
  local filename = vim.fn.fnamemodify(note_path, ":t")
  local archive_path = archive_dir .. "/" .. filename
  
  -- Read the note
  local content, read_err = utils.read_file(note_path)
  if not content then
    return false, "Failed to read note: " .. (read_err or "unknown error")
  end
  
  -- Write to archive
  ok, err = utils.write_file(archive_path, content)
  if not ok then
    return false, "Failed to write to archive: " .. (err or "unknown error")
  end
  
  -- Delete original
  local delete_ok = vim.loop.fs_unlink(note_path)
  if not delete_ok then
    return false, "Failed to delete original note"
  end
  
  return true, nil
end

--- Archive notes older than a specified number of days
---@param days number
---@return number count Number of notes archived
function M.archive_old_notes(days)
  local notes = daily.get_all_daily_notes()
  local count = 0
  local errors = {}
  
  for _, note in ipairs(notes) do
    local age = utils.file_age_days(note.path)
    if age and age > days then
      local ok, err = M.archive_note(note.path)
      if ok then
        count = count + 1
      else
        table.insert(errors, string.format("%s: %s", note.filename, err))
      end
    end
  end
  
  if #errors > 0 then
    utils.warn(string.format("Archived %d notes with %d errors", count, #errors))
    for _, error_msg in ipairs(errors) do
      utils.warn(error_msg)
    end
  else
    if count > 0 then
      utils.info(string.format("Archived %d notes", count))
    else
      utils.info("No notes to archive")
    end
  end
  
  return count
end

--- Auto-archive based on config settings
function M.auto_archive()
  local days = config.get("auto_archive_days")
  if days and days > 0 then
    return M.archive_old_notes(days)
  end
  return 0
end

--- Get all archived notes
---@return table Array of {path: string, filename: string}
function M.get_archived_notes()
  local archive_dir = utils.expand_path(config.get("archive_dir"))
  if not utils.dir_exists(archive_dir) then
    return {}
  end
  
  local files = utils.get_files(archive_dir, "%.md$")
  local notes = {}
  
  for _, filename in ipairs(files) do
    local path = archive_dir .. "/" .. filename
    table.insert(notes, {
      path = path,
      filename = filename,
    })
  end
  
  return notes
end

--- Restore a note from archive
---@param archive_path string
---@return boolean success
---@return string|nil error
function M.restore_note(archive_path)
  local notes_dir = utils.expand_path(config.get("notes_dir"))
  local filename = vim.fn.fnamemodify(archive_path, ":t")
  local restore_path = notes_dir .. "/" .. filename
  
  -- Check if note already exists
  if utils.file_exists(restore_path) then
    return false, "Note already exists in daily notes"
  end
  
  -- Read archived note
  local content, read_err = utils.read_file(archive_path)
  if not content then
    return false, "Failed to read archived note: " .. (read_err or "unknown error")
  end
  
  -- Write to notes directory
  local ok, err = utils.write_file(restore_path, content)
  if not ok then
    return false, "Failed to restore note: " .. (err or "unknown error")
  end
  
  -- Delete from archive
  local delete_ok = vim.loop.fs_unlink(archive_path)
  if not delete_ok then
    utils.warn("Note restored but failed to delete from archive")
  end
  
  return true, nil
end

--- Show archive picker
function M.show_archive_picker()
  local notes = M.get_archived_notes()
  
  if #notes == 0 then
    utils.info("No archived notes found")
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
    title = " Archived Notes ",
    title_pos = "center",
  })
  
  -- Populate buffer with notes
  local lines = {"[Press 'o' to open, 'r' to restore, 'q' to quit]", ""}
  for i, note in ipairs(notes) do
    local display = string.format("%d. %s", i, note.filename)
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
  
  local function get_selected_note()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line <= 2 then return nil end
    return notes[line - 2]
  end
  
  local function open_note()
    local note = get_selected_note()
    if note then
      close_picker()
      vim.cmd("edit " .. vim.fn.fnameescape(note.path))
    end
  end
  
  local function restore_note()
    local note = get_selected_note()
    if note then
      local ok, err = M.restore_note(note.path)
      if ok then
        close_picker()
        utils.info("Note restored: " .. note.filename)
        vim.cmd("edit " .. vim.fn.fnameescape(utils.expand_path(config.get("notes_dir")) .. "/" .. note.filename))
      else
        utils.error("Failed to restore: " .. (err or "unknown error"))
      end
    end
  end
  
  -- Keybindings
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "o", open_note, opts)
  vim.keymap.set("n", "<CR>", open_note, opts)
  vim.keymap.set("n", "r", restore_note, opts)
  vim.keymap.set("n", "<Esc>", close_picker, opts)
  vim.keymap.set("n", "q", close_picker, opts)
  vim.keymap.set("n", "<C-c>", close_picker, opts)
end

return M
