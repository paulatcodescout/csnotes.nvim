local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Get all notes (daily and general) for backlink searching
---@return table Array of note paths
local function get_all_notes()
  local all_notes = {}
  
  -- Get all daily notes
  local daily_notes = daily.get_all_daily_notes()
  for _, note in ipairs(daily_notes) do
    table.insert(all_notes, note)
  end
  
  -- Get all general notes
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  if utils.dir_exists(general_dir) then
    local general_files = utils.get_files(general_dir, "%.md$")
    for _, filename in ipairs(general_files) do
      table.insert(all_notes, {
        path = general_dir .. "/" .. filename,
        filename = filename,
      })
    end
  end
  
  return all_notes
end

--- Get all notes that link to the specified note
---@param note_path string Path to the note
---@return table Array of {path: string, filename: string, line: number, content: string}
function M.get_backlinks(note_path)
  if not config.get("linking.enabled") then
    return {}
  end
  
  local note_name = vim.fn.fnamemodify(note_path, ":t:r")
  local notes = get_all_notes()
  local backlinks = {}
  
  for _, note in ipairs(notes) do
    if note.path ~= note_path then
      local content, err = utils.read_file(note.path)
      if content then
        local links = utils.extract_links(content)
        
        -- Check if this note links to our target note
        for _, link in ipairs(links) do
          if link == note_name or link == note_name .. ".md" then
            -- Find the line where the link appears
            local line_num = 0
            -- Escape special pattern characters in note_name
            local escaped_name = note_name:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
            for line in content:gmatch("[^\r\n]+") do
              line_num = line_num + 1
              -- Match [[note]], [[note|text]], [text](note), or [text](note.md)
              if line:find("%[%[" .. escaped_name .. "[|%]]") or 
                 line:find("%]%(" .. escaped_name .. "%.?m?d?%)") then
                table.insert(backlinks, {
                  path = note.path,
                  filename = note.filename,
                  line = line_num,
                  content = line,
                })
                break
              end
            end
            break
          end
        end
      end
    end
  end
  
  return backlinks
end

--- Show backlinks for current note
function M.show_backlinks()
  if not config.get("linking.enabled") or not config.get("linking.show_backlinks") then
    utils.info("Backlinks are disabled")
    return
  end
  
  local current_file = vim.fn.expand("%:p")
  local backlinks = M.get_backlinks(current_file)
  
  if #backlinks == 0 then
    utils.info("No backlinks found")
    return
  end
  
  -- Create buffer for backlinks
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#backlinks + 3, math.floor(vim.o.lines * 0.8))
  
  local lines = {"🔗 Backlinks", ""}
  for i, backlink in ipairs(backlinks) do
    local display = string.format("%d. %s:%d - %s", 
      i, 
      backlink.filename, 
      backlink.line, 
      backlink.content:gsub("^%s+", ""))
    table.insert(lines, display)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Backlinks ",
    title_pos = "center",
  })
  
  -- Set up keymaps
  local function close_win()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  local function open_backlink()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line <= 2 then return end
    
    local backlink = backlinks[line - 2]
    if backlink then
      close_win()
      vim.cmd("edit " .. vim.fn.fnameescape(backlink.path))
      vim.api.nvim_win_set_cursor(0, {backlink.line, 0})
    end
  end
  
  vim.keymap.set("n", "<CR>", open_backlink, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
end

--- Insert a link to another note
---@param note_name string|nil Name of note to link to (prompts if nil)
function M.insert_link(note_name)
  if not config.get("linking.enabled") then
    utils.info("Linking is disabled")
    return
  end
  
  local style = config.get("linking.style") or "wiki"
  
  if not note_name then
    vim.ui.input({ prompt = "Link to note: " }, function(input)
      if input and input ~= "" then
        M.insert_link(input)
      end
    end)
    return
  end
  
  local link_text
  if style == "wiki" then
    link_text = string.format("[[%s]]", note_name)
  else
    link_text = string.format("[%s](%s.md)", note_name, note_name)
  end
  
  -- Insert at cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. link_text .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  
  -- Move cursor after the link
  vim.api.nvim_win_set_cursor(0, {row, col + #link_text})
end

--- Follow link under cursor
function M.follow_link()
  if not config.get("linking.enabled") then
    utils.info("Linking is disabled")
    return
  end
  
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Try to find a wiki-style link [[note|alternative text]] or [[note]]
  -- Pattern captures everything between [[ and ]]
  local wiki_pattern = "%[%[([^%]]+)%]%]"
  for full_match in line:gmatch(wiki_pattern) do
    -- Escape special characters for pattern matching
    local escaped_match = full_match:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local start_pos, end_pos = line:find("%[%[" .. escaped_match .. "%]%]")
    
    if start_pos and end_pos and col >= start_pos - 1 and col <= end_pos then
      -- Extract the note name (part before |, or the whole thing if no |)
      local note_name = full_match:match("^([^|]+)") or full_match
      -- Trim whitespace
      note_name = note_name:match("^%s*(.-)%s*$")
      M.open_linked_note(note_name)
      return
    end
  end
  
  -- Try to find a markdown-style link [text](note.md) or [text](note)
  local md_pattern = "%[([^%]]+)%]%(([^%)]+)%)"
  for display_text, note_file in line:gmatch(md_pattern) do
    -- Escape special characters for pattern matching
    local escaped_text = display_text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local escaped_file = note_file:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local start_pos, end_pos = line:find("%[" .. escaped_text .. "%]%(" .. escaped_file .. "%)")
    
    if start_pos and end_pos and col >= start_pos - 1 and col <= end_pos then
      -- Remove .md extension if present
      local note_name = note_file:match("^(.+)%.md$") or note_file
      -- Trim whitespace
      note_name = note_name:match("^%s*(.-)%s*$")
      M.open_linked_note(note_name)
      return
    end
  end
  
  utils.warn("No link found under cursor")
end

--- Open a linked note
---@param note_name string Name of the note
function M.open_linked_note(note_name)
  -- Try to find the note in multiple locations
  local search_dirs = {
    utils.expand_path(config.get("notes_dir")),
    utils.expand_path(config.get("general_notes_dir")),
  }
  
  local note_path = nil
  for _, dir in ipairs(search_dirs) do
    local candidate = dir .. "/" .. note_name
    if not candidate:match("%.md$") then
      candidate = candidate .. ".md"
    end
    if utils.file_exists(candidate) then
      note_path = candidate
      break
    end
  end
  
  if note_path then
    vim.cmd("edit " .. vim.fn.fnameescape(note_path))
  else
    -- Ask where to create the note
    vim.ui.select(
      {"Daily notes", "General notes", "Cancel"},
      {prompt = string.format("Note '%s' does not exist. Where to create?", note_name)},
      function(choice)
        if choice == "Daily notes" then
          local path = search_dirs[1] .. "/" .. note_name
          if not path:match("%.md$") then
            path = path .. ".md"
          end
          vim.cmd("edit " .. vim.fn.fnameescape(path))
        elseif choice == "General notes" then
          local path = search_dirs[2] .. "/" .. note_name
          if not path:match("%.md$") then
            path = path .. ".md"
          end
          vim.cmd("edit " .. vim.fn.fnameescape(path))
        end
      end
    )
  end
end

--- Get all outgoing links from current note
---@return table Array of note names
function M.get_outgoing_links()
  local current_file = vim.fn.expand("%:p")
  local content, err = utils.read_file(current_file)
  
  if not content then
    return {}
  end
  
  return utils.extract_links(content)
end

--- Show all links (outgoing and backlinks) for current note
function M.show_all_links()
  local current_file = vim.fn.expand("%:p")
  local current_name = vim.fn.fnamemodify(current_file, ":t:r")
  
  local outgoing = M.get_outgoing_links()
  local backlinks = M.get_backlinks(current_file)
  
  local lines = {
    string.format("🔗 Links for: %s", current_name),
    "",
    "📤 Outgoing Links:",
  }
  
  if #outgoing == 0 then
    table.insert(lines, "  (none)")
  else
    for _, link in ipairs(outgoing) do
      table.insert(lines, "  • " .. link)
    end
  end
  
  table.insert(lines, "")
  table.insert(lines, "📥 Backlinks:")
  
  if #backlinks == 0 then
    table.insert(lines, "  (none)")
  else
    for _, backlink in ipairs(backlinks) do
      table.insert(lines, string.format("  • %s (line %d)", backlink.filename, backlink.line))
    end
  end
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.8))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })
  
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })
end

return M
