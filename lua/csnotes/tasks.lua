local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Task priority levels
M.PRIORITY = {
  HIGH = "high",
  MEDIUM = "medium",
  LOW = "low",
  NONE = "none",
}

--- Parse tasks from content
---@param content string Note content
---@return table Array of task objects
function M.parse_tasks(content)
  local tasks = {}
  local line_num = 0
  
  for line in content:gmatch("[^\r\n]+") do
    line_num = line_num + 1
    
    -- Match checkbox patterns: - [ ] or - [x] or - [X]
    local indent, checkbox, text = line:match("^(%s*)%-%s+%[([%sxX])%]%s+(.+)$")
    
    if checkbox and text then
      local completed = checkbox:lower() == "x"
      
      -- Extract priority markers (!, !!, !!!)
      local priority = M.PRIORITY.NONE
      local priority_markers = text:match("^(!+)")
      if priority_markers then
        if #priority_markers >= 3 then
          priority = M.PRIORITY.HIGH
        elseif #priority_markers == 2 then
          priority = M.PRIORITY.MEDIUM
        else
          priority = M.PRIORITY.LOW
        end
        text = text:gsub("^!+%s*", "") -- Remove priority markers
      end
      
      -- Extract due date (@due: YYYY-MM-DD or @due:YYYY-MM-DD)
      local due_date = text:match("@due:%s*(%d%d%d%d%-%d%d%-%d%d)")
      if due_date then
        text = text:gsub("@due:%s*%d%d%d%d%-%d%d%-%d%d%s*", "")
      end
      
      -- Extract tags
      local tags = {}
      for tag in text:gmatch("#([%w_%-]+)") do
        table.insert(tags, tag)
      end
      
      table.insert(tasks, {
        line = line_num,
        text = vim.trim(text),
        completed = completed,
        priority = priority,
        due_date = due_date,
        tags = tags,
        indent_level = #(indent or ""),
        raw = line,
      })
    end
  end
  
  return tasks
end

--- Get all tasks from a note file
---@param path string Note file path
---@return table|nil tasks, string|nil error
function M.get_tasks_from_file(path)
  local content, err = utils.read_file(path)
  if not content then
    return nil, err
  end
  
  local tasks = M.parse_tasks(content)
  
  -- Add file information to each task
  for _, task in ipairs(tasks) do
    task.file = path
    task.filename = vim.fn.fnamemodify(path, ":t")
  end
  
  return tasks, nil
end

--- Get all tasks from all daily notes
---@param filter table|nil Filter options {completed: bool, priority: string, tags: table, overdue: bool}
---@return table Array of task objects
function M.get_all_tasks(filter)
  filter = filter or {}
  local notes = daily.get_all_daily_notes()
  local all_tasks = {}
  
  for _, note in ipairs(notes) do
    local tasks, err = M.get_tasks_from_file(note.path)
    if tasks then
      for _, task in ipairs(tasks) do
        -- Add note date info
        task.note_date = note.date
        task.note_timestamp = note.timestamp
        
        -- Apply filters
        local include = true
        
        -- Filter by completion status
        if filter.completed ~= nil and task.completed ~= filter.completed then
          include = false
        end
        
        -- Filter by priority
        if filter.priority and task.priority ~= filter.priority then
          include = false
        end
        
        -- Filter by tags
        if filter.tags and #filter.tags > 0 then
          local has_tag = false
          for _, filter_tag in ipairs(filter.tags) do
            if vim.tbl_contains(task.tags, filter_tag) then
              has_tag = true
              break
            end
          end
          if not has_tag then
            include = false
          end
        end
        
        -- Filter overdue tasks
        if filter.overdue and task.due_date then
          local today = os.date("%Y-%m-%d")
          if task.due_date >= today then
            include = false
          end
        end
        
        if include then
          table.insert(all_tasks, task)
        end
      end
    end
  end
  
  return all_tasks
end

--- Get incomplete tasks from all notes
---@return table Array of incomplete task objects
function M.get_incomplete_tasks()
  return M.get_all_tasks({ completed = false })
end

--- Get completed tasks from all notes
---@return table Array of completed task objects
function M.get_completed_tasks()
  return M.get_all_tasks({ completed = true })
end

--- Get overdue tasks
---@return table Array of overdue task objects
function M.get_overdue_tasks()
  local all_tasks = M.get_all_tasks({ completed = false })
  local overdue = {}
  local today = os.date("%Y-%m-%d")
  
  for _, task in ipairs(all_tasks) do
    if task.due_date and task.due_date < today then
      table.insert(overdue, task)
    end
  end
  
  return overdue
end

--- Sort tasks by various criteria
---@param tasks table Array of tasks
---@param sort_by string Sort criteria: "priority", "due_date", "date", "file"
---@return table Sorted tasks
function M.sort_tasks(tasks, sort_by)
  sort_by = sort_by or "date"
  
  local priority_order = {
    [M.PRIORITY.HIGH] = 1,
    [M.PRIORITY.MEDIUM] = 2,
    [M.PRIORITY.LOW] = 3,
    [M.PRIORITY.NONE] = 4,
  }
  
  table.sort(tasks, function(a, b)
    if sort_by == "priority" then
      return priority_order[a.priority] < priority_order[b.priority]
    elseif sort_by == "due_date" then
      if a.due_date and b.due_date then
        return a.due_date < b.due_date
      elseif a.due_date then
        return true
      elseif b.due_date then
        return false
      end
      return false
    elseif sort_by == "date" then
      if a.note_timestamp and b.note_timestamp then
        return a.note_timestamp > b.note_timestamp
      end
      return a.filename > b.filename
    elseif sort_by == "file" then
      return a.filename < b.filename
    end
    return false
  end)
  
  return tasks
end

--- Generate a task report
---@param options table|nil Options {completed: bool, sort_by: string, format: string}
---@return string report
function M.generate_report(options)
  options = options or {}
  local completed = options.completed
  local sort_by = options.sort_by or "date"
  local format = options.format or "text"
  
  local tasks
  if completed == true then
    tasks = M.get_completed_tasks()
  elseif completed == false then
    tasks = M.get_incomplete_tasks()
  else
    tasks = M.get_all_tasks()
  end
  
  tasks = M.sort_tasks(tasks, sort_by)
  
  local lines = {}
  
  if format == "markdown" then
    table.insert(lines, "# Task Report")
    table.insert(lines, "")
    table.insert(lines, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
    table.insert(lines, string.format("Total tasks: %d", #tasks))
    table.insert(lines, "")
    
    local current_file = nil
    for _, task in ipairs(tasks) do
      if task.filename ~= current_file then
        current_file = task.filename
        table.insert(lines, "")
        table.insert(lines, string.format("## %s", current_file))
        table.insert(lines, "")
      end
      
      local checkbox = task.completed and "[x]" or "[ ]"
      local priority_marker = ""
      if task.priority == M.PRIORITY.HIGH then
        priority_marker = "!!! "
      elseif task.priority == M.PRIORITY.MEDIUM then
        priority_marker = "!! "
      elseif task.priority == M.PRIORITY.LOW then
        priority_marker = "! "
      end
      
      local due_info = task.due_date and string.format(" @due:%s", task.due_date) or ""
      local tag_info = #task.tags > 0 and " " .. table.concat(vim.tbl_map(function(t) return "#" .. t end, task.tags), " ") or ""
      
      table.insert(lines, string.format("- %s %s%s%s%s", checkbox, priority_marker, task.text, due_info, tag_info))
    end
  else
    table.insert(lines, "Task Report")
    table.insert(lines, string.rep("=", 80))
    table.insert(lines, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
    table.insert(lines, string.format("Total tasks: %d", #tasks))
    table.insert(lines, "")
    
    for _, task in ipairs(tasks) do
      local status = task.completed and "[✓]" or "[ ]"
      local priority_icon = ""
      if task.priority == M.PRIORITY.HIGH then
        priority_icon = "🔴 "
      elseif task.priority == M.PRIORITY.MEDIUM then
        priority_icon = "🟡 "
      elseif task.priority == M.PRIORITY.LOW then
        priority_icon = "🟢 "
      end
      
      local due_info = task.due_date and string.format(" (Due: %s)", task.due_date) or ""
      
      table.insert(lines, string.format("%s %s%s%s", status, priority_icon, task.text, due_info))
      table.insert(lines, string.format("    File: %s (line %d)", task.filename, task.line))
      table.insert(lines, "")
    end
  end
  
  return table.concat(lines, "\n")
end

--- Show task report in a floating window
---@param options table|nil Options for report generation
function M.show_report(options)
  options = options or { completed = false, sort_by = "priority" }
  
  local tasks
  if options.completed == true then
    tasks = M.get_completed_tasks()
  elseif options.completed == false then
    tasks = M.get_incomplete_tasks()
  else
    tasks = M.get_all_tasks()
  end
  
  tasks = M.sort_tasks(tasks, options.sort_by or "priority")
  
  if #tasks == 0 then
    utils.info("No tasks found")
    return
  end
  
  -- Create buffer for report
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.min(#tasks + 10, math.floor(vim.o.lines * 0.9))
  
  local lines = {
    "📋 Task Report",
    "",
    string.format("Total: %d tasks | Status: %s | Sort: %s", 
      #tasks, 
      options.completed == false and "Incomplete" or options.completed == true and "Completed" or "All",
      options.sort_by or "priority"
    ),
    string.rep("─", 80),
    "",
  }
  
  local task_map = {}
  for i, task in ipairs(tasks) do
    local status = task.completed and "[✓]" or "[ ]"
    local priority_icon = ""
    if task.priority == M.PRIORITY.HIGH then
      priority_icon = "🔴 "
    elseif task.priority == M.PRIORITY.MEDIUM then
      priority_icon = "🟡 "
    elseif task.priority == M.PRIORITY.LOW then
      priority_icon = "🟢 "
    end
    
    local due_info = ""
    if task.due_date then
      local today = os.date("%Y-%m-%d")
      if task.due_date < today then
        due_info = string.format(" [⚠️ OVERDUE: %s]", task.due_date)
      else
        due_info = string.format(" [📅 %s]", task.due_date)
      end
    end
    
    local tag_info = #task.tags > 0 and " " .. table.concat(vim.tbl_map(function(t) return "#" .. t end, task.tags), " ") or ""
    
    table.insert(lines, string.format("%d. %s %s%s%s%s", 
      i, status, priority_icon, task.text, due_info, tag_info))
    table.insert(lines, string.format("   📄 %s:%d", task.filename, task.line))
    
    task_map[#lines - 1] = task
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "csnotes-tasks")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Tasks ",
    title_pos = "center",
  })
  
  -- Set up keymaps
  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  local function open_task()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local task = task_map[line]
    if task then
      close_win()
      vim.cmd("edit " .. vim.fn.fnameescape(task.file))
      vim.api.nvim_win_set_cursor(0, {task.line, 0})
      vim.cmd("normal! zz")
    end
  end
  
  vim.keymap.set("n", "<CR>", open_task, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "?", function()
    utils.info("Enter: Open task | q/Esc: Close | s: Change sort | f: Filter")
  end, { buffer = buf, nowait = true })
end

--- Export task report to a file
---@param filepath string Output file path
---@param options table|nil Report options
---@return boolean success
function M.export_report(filepath, options)
  options = options or { completed = false, sort_by = "priority", format = "markdown" }
  local report = M.generate_report(options)
  
  local ok, err = utils.write_file(filepath, report)
  if ok then
    utils.info(string.format("Task report exported to: %s", filepath))
    return true
  else
    utils.error(string.format("Failed to export report: %s", err or "unknown error"))
    return false
  end
end

--- Get task statistics
---@return table Statistics
function M.get_statistics()
  local all_tasks = M.get_all_tasks()
  local incomplete = M.get_incomplete_tasks()
  local completed = M.get_completed_tasks()
  local overdue = M.get_overdue_tasks()
  
  local by_priority = {
    high = 0,
    medium = 0,
    low = 0,
    none = 0,
  }
  
  for _, task in ipairs(incomplete) do
    by_priority[task.priority] = by_priority[task.priority] + 1
  end
  
  return {
    total = #all_tasks,
    completed = #completed,
    incomplete = #incomplete,
    overdue = #overdue,
    completion_rate = #all_tasks > 0 and math.floor((#completed / #all_tasks) * 100) or 0,
    by_priority = by_priority,
  }
end

return M
