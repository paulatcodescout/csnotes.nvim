local utils = require("csnotes.utils")
local config = require("csnotes.config")

local M = {}

--- Get the path for today's daily note
---@param date_format string|nil Custom date format
---@return string
function M.get_daily_note_path(date_format)
  date_format = date_format or config.get("date_format")
  local notes_dir = utils.expand_path(config.get("notes_dir"))
  local filename = utils.format_date(date_format, nil) .. ".md"
  return notes_dir .. "/" .. filename
end

--- Get the path for a specific date's daily note
---@param timestamp number Unix timestamp
---@param date_format string|nil Custom date format
---@return string
function M.get_daily_note_path_for_date(timestamp, date_format)
  date_format = date_format or config.get("date_format")
  local notes_dir = utils.expand_path(config.get("notes_dir"))
  local filename = utils.format_date(date_format, timestamp) .. ".md"
  return notes_dir .. "/" .. filename
end

--- Create a new daily note with template
---@param path string
---@return boolean success
---@return string|nil error
function M.create_daily_note(path)
  local template = config.get("template")
  local header_date_format = config.get("header_date_format")
  local date_str = utils.format_date(header_date_format, nil)
  
  -- Replace {date} placeholder in template
  local content = template:gsub("{date}", date_str)
  
  -- Ensure directory exists
  local dir = vim.fn.fnamemodify(path, ":h")
  local ok, err = utils.mkdir_p(dir)
  if not ok then
    return false, "Failed to create directory: " .. (err or "unknown error")
  end
  
  -- Write the file
  ok, err = utils.write_file(path, content)
  if not ok then
    return false, "Failed to create note: " .. (err or "unknown error")
  end
  
  -- Create backup if enabled
  if config.get("backup.enabled") and config.get("backup.on_save") then
    M.backup_note(path)
  end
  
  return true, nil
end

--- Open or create today's daily note
---@param opts table|nil Options (split: "vertical"|"horizontal"|nil)
function M.open_daily_note(opts)
  opts = opts or {}
  local path = M.get_daily_note_path()
  local is_new = not utils.file_exists(path)
  
  -- Create the note if it doesn't exist
  if is_new then
    local ok, err = M.create_daily_note(path)
    if not ok then
      utils.error(err)
      return
    end
    utils.info("Created new daily note")
  end
  
  -- Open the file
  local cmd = "edit"
  if opts.split == "vertical" then
    cmd = "vsplit"
  elseif opts.split == "horizontal" then
    cmd = "split"
  end
  
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
  
  -- Position cursor at a good location (after headers)
  if is_new then
    vim.cmd("normal! G")
  end
end

--- Open the general notes file
---@param opts table|nil Options (split: "vertical"|"horizontal"|nil)
function M.open_general_notes(opts)
  opts = opts or {}
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  local filename = config.get("general_notes_file")
  local path = general_dir .. "/" .. filename
  local is_new = not utils.file_exists(path)
  
  -- Create the file if it doesn't exist
  if is_new then
    local ok, err = utils.mkdir_p(general_dir)
    if not ok then
      utils.error("Failed to create general notes directory: " .. (err or "unknown error"))
      return
    end
    
    local content = "# General Notes\n\n"
    ok, err = utils.write_file(path, content)
    if not ok then
      utils.error("Failed to create general notes file: " .. (err or "unknown error"))
      return
    end
    utils.info("Created general notes file")
  end
  
  -- Open the file
  local cmd = "edit"
  if opts.split == "vertical" then
    cmd = "vsplit"
  elseif opts.split == "horizontal" then
    cmd = "split"
  end
  
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
end

--- Toggle between daily note and general notes
function M.toggle_daily_general()
  local current_file = vim.fn.expand("%:p")
  local daily_path = M.get_daily_note_path()
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  local general_path = general_dir .. "/" .. config.get("general_notes_file")
  
  if current_file == daily_path then
    M.open_general_notes()
  else
    M.open_daily_note()
  end
end

--- Backup a note file
---@param path string
---@return boolean success
function M.backup_note(path)
  if not config.get("backup.enabled") then
    return false
  end
  
  local backup_dir = utils.expand_path(config.get("backup.dir"))
  local ok, err = utils.mkdir_p(backup_dir)
  if not ok then
    utils.warn("Failed to create backup directory: " .. (err or "unknown error"))
    return false
  end
  
  local filename = vim.fn.fnamemodify(path, ":t:r")
  local ext = vim.fn.fnamemodify(path, ":e")
  local timestamp = utils.format_date("%Y%m%d_%H%M%S")
  local backup_path = string.format("%s/%s_%s.%s", backup_dir, filename, timestamp, ext)
  
  local content, read_err = utils.read_file(path)
  if not content then
    utils.warn("Failed to read file for backup: " .. (read_err or "unknown error"))
    return false
  end
  
  ok, err = utils.write_file(backup_path, content)
  if not ok then
    utils.warn("Failed to create backup: " .. (err or "unknown error"))
    return false
  end
  
  return true
end

--- Get all daily notes
---@return table Array of {path: string, filename: string, date: string, timestamp: number|nil}
function M.get_all_daily_notes()
  local notes_dir = utils.expand_path(config.get("notes_dir"))
  local files = utils.get_files(notes_dir, "%.md$")
  local notes = {}
  
  for _, filename in ipairs(files) do
    local path = notes_dir .. "/" .. filename
    local timestamp = utils.parse_date_from_filename(filename, config.get("date_format"))
    local date_str = filename:match("^(.+)%.md$") or filename
    
    table.insert(notes, {
      path = path,
      filename = filename,
      date = date_str,
      timestamp = timestamp,
    })
  end
  
  return notes
end

--- Search within daily notes
---@param query string
---@return table Array of {path: string, line: number, content: string}
function M.search_notes(query)
  local notes = M.get_all_daily_notes()
  local results = {}
  
  for _, note in ipairs(notes) do
    local content, err = utils.read_file(note.path)
    if content then
      local line_num = 0
      for line in content:gmatch("[^\r\n]+") do
        line_num = line_num + 1
        if line:lower():find(query:lower(), 1, true) then
          table.insert(results, {
            path = note.path,
            filename = note.filename,
            line = line_num,
            content = line,
          })
        end
      end
    end
  end
  
  return results
end

return M
