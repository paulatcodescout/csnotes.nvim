local M = {}

--- Check if a file exists
---@param path string
---@return boolean
function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

--- Check if a directory exists
---@param path string
---@return boolean
function M.dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

--- Create a directory recursively
---@param path string
---@return boolean success
---@return string|nil error
function M.mkdir_p(path)
  local ok, err = vim.loop.fs_mkdir(path, 493) -- 493 = 0755 in octal
  if ok or (err and err:match("EEXIST")) then
    return true, nil
  end
  
  -- Try to create parent directories
  local parent = vim.fn.fnamemodify(path, ':h')
  if parent ~= path then
    local parent_ok, parent_err = M.mkdir_p(parent)
    if not parent_ok then
      return false, parent_err
    end
    return M.mkdir_p(path)
  end
  
  return false, err
end

--- Expand path with tilde and environment variables
---@param path string
---@return string
function M.expand_path(path)
  return vim.fn.expand(path)
end

--- Get all files in a directory matching a pattern
---@param dir string
---@param pattern string|nil
---@return table
function M.get_files(dir, pattern)
  local files = {}
  local handle = vim.loop.fs_scandir(M.expand_path(dir))
  
  if not handle then
    return files
  end
  
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    
    if type == 'file' then
      if not pattern or name:match(pattern) then
        table.insert(files, name)
      end
    end
  end
  
  table.sort(files, function(a, b) return a > b end) -- Sort descending (newest first)
  return files
end

--- Format a date according to a format string
---@param format string strftime format
---@param time number|nil Unix timestamp (defaults to current time)
---@return string
function M.format_date(format, time)
  return os.date(format, time)
end

--- Parse a date from a filename
---@param filename string
---@param format string
---@return number|nil timestamp
function M.parse_date_from_filename(filename, format)
  -- Remove extension
  local base = filename:match("^(.+)%.%w+$") or filename
  
  -- Try to parse based on common formats
  local year, month, day = base:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if year and month and day then
    return os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
  end
  
  return nil
end

--- Show an error message
---@param msg string
function M.error(msg)
  vim.notify("CSNotes: " .. msg, vim.log.levels.ERROR)
end

--- Show an info message
---@param msg string
function M.info(msg)
  vim.notify("CSNotes: " .. msg, vim.log.levels.INFO)
end

--- Show a warning message
---@param msg string
function M.warn(msg)
  vim.notify("CSNotes: " .. msg, vim.log.levels.WARN)
end

--- Extract tags from note content
---@param content string
---@return table
function M.extract_tags(content)
  local tags = {}
  -- Match #tag patterns
  for tag in content:gmatch("#([%w_%-]+)") do
    if not vim.tbl_contains(tags, tag) then
      table.insert(tags, tag)
    end
  end
  return tags
end

--- Read file contents
---@param path string
---@return string|nil content
---@return string|nil error
function M.read_file(path)
  local file, err = io.open(path, "r")
  if not file then
    return nil, err
  end
  
  local content = file:read("*a")
  file:close()
  return content, nil
end

--- Write file contents
---@param path string
---@param content string
---@return boolean success
---@return string|nil error
function M.write_file(path, content)
  local file, err = io.open(path, "w")
  if not file then
    return false, err
  end
  
  file:write(content)
  file:close()
  return true, nil
end

--- Get the age of a file in days
---@param path string
---@return number|nil days
function M.file_age_days(path)
  local stat = vim.loop.fs_stat(path)
  if not stat then
    return nil
  end
  
  local now = os.time()
  local age_seconds = now - stat.mtime.sec
  return math.floor(age_seconds / 86400) -- 86400 seconds in a day
end

return M
