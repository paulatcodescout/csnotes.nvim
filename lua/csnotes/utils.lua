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

--- Get the start of the week (Monday) for a given timestamp
---@param timestamp number|nil Unix timestamp (defaults to current time)
---@return number timestamp of Monday at 00:00:00
function M.get_week_start(timestamp)
  timestamp = timestamp or os.time()
  local date = os.date("*t", timestamp)
  
  -- Get day of week (1=Sunday, 2=Monday, ..., 7=Saturday)
  local wday = date.wday
  
  -- Calculate days to subtract to get to Monday
  local days_to_monday = (wday == 1) and 6 or (wday - 2)
  
  -- Get Monday's date
  local monday = os.time({
    year = date.year,
    month = date.month,
    day = date.day - days_to_monday,
    hour = 0,
    min = 0,
    sec = 0
  })
  
  return monday
end

--- Get the end of the week (Sunday) for a given timestamp
---@param timestamp number|nil Unix timestamp (defaults to current time)
---@return number timestamp of Sunday at 23:59:59
function M.get_week_end(timestamp)
  timestamp = timestamp or os.time()
  local monday = M.get_week_start(timestamp)
  
  -- Add 6 days to get Sunday
  local sunday = monday + (6 * 86400)
  local date = os.date("*t", sunday)
  
  return os.time({
    year = date.year,
    month = date.month,
    day = date.day,
    hour = 23,
    min = 59,
    sec = 59
  })
end

--- Format a week range string
---@param timestamp number|nil Unix timestamp (defaults to current time)
---@return string e.g., "January 1 - January 7, 2024"
function M.format_week_range(timestamp)
  local week_start = M.get_week_start(timestamp)
  local week_end = M.get_week_end(timestamp)
  
  local start_str = os.date("%B %d", week_start)
  local end_str = os.date("%B %d, %Y", week_end)
  
  return start_str .. " - " .. end_str
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

--- Parse frontmatter from content
---@param content string
---@return table|nil frontmatter
---@return string content_without_frontmatter
function M.parse_frontmatter(content)
  -- Check for YAML frontmatter (--- ... ---)
  local yaml_pattern = "^%-%-%-\n(.-)%-%-%-\n(.*)$"
  local yaml_match, yaml_body = content:match(yaml_pattern)
  
  if yaml_match then
    local frontmatter = {}
    for line in yaml_match:gmatch("[^\r\n]+") do
      local key, value = line:match("^([%w_]+):%s*(.+)$")
      if key and value then
        -- Handle arrays
        if value:match("^%[.-%]$") then
          local items = {}
          for item in value:gmatch("%[(.-)%]") do
            for v in item:gmatch("[^,]+") do
              table.insert(items, v:match("^%s*(.-)%s*$"))
            end
          end
          frontmatter[key] = items
        else
          frontmatter[key] = value:match("^%s*(.-)%s*$")
        end
      end
    end
    return frontmatter, yaml_body
  end
  
  return nil, content
end

--- Generate frontmatter string
---@param metadata table
---@return string
function M.generate_frontmatter(metadata)
  local lines = {"---"}
  
  for key, value in pairs(metadata) do
    if type(value) == "table" then
      table.insert(lines, string.format("%s: [%s]", key, table.concat(value, ", ")))
    else
      table.insert(lines, string.format("%s: %s", key, value))
    end
  end
  
  table.insert(lines, "---")
  return table.concat(lines, "\n") .. "\n"
end

--- Update frontmatter in content
---@param content string
---@param updates table
---@return string
function M.update_frontmatter(content, updates)
  local frontmatter, body = M.parse_frontmatter(content)
  
  if not frontmatter then
    frontmatter = {}
  end
  
  -- Merge updates
  for key, value in pairs(updates) do
    frontmatter[key] = value
  end
  
  return M.generate_frontmatter(frontmatter) .. body
end

--- Get file modification time
---@param path string
---@return number|nil timestamp
function M.get_mtime(path)
  local stat = vim.loop.fs_stat(path)
  if stat then
    return stat.mtime.sec
  end
  return nil
end

--- Get file creation time (best effort)
---@param path string
---@return number|nil timestamp
function M.get_ctime(path)
  local stat = vim.loop.fs_stat(path)
  if stat then
    return stat.birthtime and stat.birthtime.sec or stat.ctime.sec
  end
  return nil
end

--- Extract note links from content
---@param content string
---@return table Array of linked note names
function M.extract_links(content)
  local links = {}
  
  -- Match [[note name|alternative text]] or [[note name]] style links
  for link in content:gmatch("%[%[([^%]]+)%]%]") do
    -- Extract the note name (part before |, or the whole thing if no |)
    local note_name = link:match("^([^|]+)") or link
    -- Trim whitespace
    note_name = note_name:match("^%s*(.-)%s*$")
    if note_name and note_name ~= "" and not vim.tbl_contains(links, note_name) then
      table.insert(links, note_name)
    end
  end
  
  -- Match [text](note.md) or [text](note) style links
  for link in content:gmatch("%]%(([^%)]+)%)") do
    -- Remove .md extension if present
    local note_name = link:match("^(.+)%.md$") or link
    -- Trim whitespace
    note_name = note_name:match("^%s*(.-)%s*$")
    if note_name and note_name ~= "" and not vim.tbl_contains(links, note_name) then
      table.insert(links, note_name)
    end
  end
  
  return links
end

--- Count words in content
---@param content string
---@return number
function M.count_words(content)
  local count = 0
  for _ in content:gmatch("%S+") do
    count = count + 1
  end
  return count
end

--- Count lines in content
---@param content string
---@return number
function M.count_lines(content)
  local count = 0
  for _ in content:gmatch("[^\r\n]+") do
    count = count + 1
  end
  return count
end

return M
