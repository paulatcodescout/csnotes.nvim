local utils = require("csnotes.utils")
local config = require("csnotes.config")
local daily = require("csnotes.daily")

local M = {}

--- Get statistics for a single note
---@param path string Note file path
---@return table|nil stats
function M.get_note_stats(path)
  if not utils.file_exists(path) then
    return nil
  end
  
  local content, err = utils.read_file(path)
  if not content then
    return nil
  end
  
  local frontmatter, body = utils.parse_frontmatter(content)
  
  return {
    path = path,
    filename = vim.fn.fnamemodify(path, ":t"),
    word_count = utils.count_words(body or content),
    line_count = utils.count_lines(body or content),
    char_count = #(body or content),
    tag_count = #utils.extract_tags(body or content),
    link_count = #utils.extract_links(body or content),
    created = frontmatter and frontmatter.created or nil,
    modified = frontmatter and frontmatter.modified or nil,
    file_size = vim.fn.getfsize(path),
  }
end

--- Get aggregate statistics for all notes
---@return table stats
function M.get_all_stats()
  local notes = daily.get_all_daily_notes()
  local total_words = 0
  local total_lines = 0
  local total_tags = 0
  local total_links = 0
  local total_files = #notes
  
  for _, note in ipairs(notes) do
    local stats = M.get_note_stats(note.path)
    if stats then
      total_words = total_words + stats.word_count
      total_lines = total_lines + stats.line_count
      total_tags = total_tags + stats.tag_count
      total_links = total_links + stats.link_count
    end
  end
  
  return {
    total_notes = total_files,
    total_words = total_words,
    total_lines = total_lines,
    total_tags = total_tags,
    total_links = total_links,
    avg_words_per_note = total_files > 0 and math.floor(total_words / total_files) or 0,
    avg_lines_per_note = total_files > 0 and math.floor(total_lines / total_files) or 0,
  }
end

--- Display statistics for current buffer
function M.show_current_stats()
  if not config.get("statistics.enabled") then
    utils.info("Statistics are disabled")
    return
  end
  
  local current_file = vim.fn.expand("%:p")
  local stats = M.get_note_stats(current_file)
  
  if not stats then
    utils.error("Failed to get statistics for current file")
    return
  end
  
  local lines = {
    "📊 Note Statistics",
    "",
    string.format("📄 File: %s", stats.filename),
    string.format("📝 Words: %d", stats.word_count),
    string.format("📏 Lines: %d", stats.line_count),
    string.format("💾 Size: %.2f KB", stats.file_size / 1024),
    string.format("🏷️  Tags: %d", stats.tag_count),
    string.format("🔗 Links: %d", stats.link_count),
  }
  
  if stats.created then
    table.insert(lines, string.format("📅 Created: %s", stats.created))
  end
  
  if stats.modified then
    table.insert(lines, string.format("🔄 Modified: %s", stats.modified))
  end
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 50
  local height = #lines
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    width = width,
    height = height,
    row = 1,
    col = 0,
    style = "minimal",
    border = "rounded",
  })
  
  -- Auto-close after 5 seconds or on any key
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 5000)
  
  vim.keymap.set("n", "<Esc>", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true })
end

--- Display aggregate statistics
function M.show_aggregate_stats()
  if not config.get("statistics.enabled") then
    utils.info("Statistics are disabled")
    return
  end
  
  utils.info("Calculating statistics...")
  
  local stats = M.get_all_stats()
  
  local lines = {
    "📊 All Notes Statistics",
    "",
    string.format("📚 Total Notes: %d", stats.total_notes),
    string.format("📝 Total Words: %s", string.format("%d", stats.total_words):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")),
    string.format("📏 Total Lines: %s", string.format("%d", stats.total_lines):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")),
    string.format("🏷️  Total Tags: %d", stats.total_tags),
    string.format("🔗 Total Links: %d", stats.total_links),
    "",
    string.format("📊 Avg Words/Note: %d", stats.avg_words_per_note),
    string.format("📊 Avg Lines/Note: %d", stats.avg_lines_per_note),
  }
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 50
  local height = #lines
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
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
