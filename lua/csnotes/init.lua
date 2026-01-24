local config = require("csnotes.config")
local daily = require("csnotes.daily")
local list = require("csnotes.list")
local tags = require("csnotes.tags")
local archive = require("csnotes.archive")

local M = {}

-- Lazy-load modules
local function get_statistics()
  return require("csnotes.statistics")
end

local function get_linking()
  return require("csnotes.linking")
end

local function get_frontmatter()
  return require("csnotes.frontmatter")
end

local function get_tasks()
  return require("csnotes.tasks")
end

local function get_para()
  return require("csnotes.para")
end

--- Setup the plugin
---@param opts table|nil User configuration
function M.setup(opts)
  config.setup(opts)
  
  -- Auto-archive on startup if configured
  if config.get("auto_archive_days") and config.get("auto_archive_days") > 0 then
    vim.defer_fn(function()
      archive.auto_archive()
    end, 1000)
  end
  
  -- Set up autocommands
  local group = vim.api.nvim_create_augroup("CSNotes", { clear = true })
  
  -- Backup on save
  if config.get("backup.enabled") and config.get("backup.on_save") then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      pattern = "*.md",
      callback = function()
        local file_path = vim.fn.expand("%:p")
        local notes_dir = vim.fn.expand(config.get("notes_dir"))
        
        -- Only backup files in the notes directory
        if file_path:find(notes_dir, 1, true) == 1 then
          daily.backup_note(file_path)
        end
      end,
    })
  end
  
  -- Update frontmatter modified time on save
  if config.get("frontmatter.enabled") and config.get("frontmatter.auto_update_modified") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      pattern = "*.md",
      callback = function()
        local file_path = vim.fn.expand("%:p")
        local notes_dir = vim.fn.expand(config.get("notes_dir"))
        
        -- Only update files in the notes directory
        if file_path:find(notes_dir, 1, true) == 1 then
          get_frontmatter().update_modified_time(file_path)
        end
      end,
    })
  end
  
  -- Show statistics on open if configured
  if config.get("statistics.enabled") and config.get("statistics.show_on_open") then
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      pattern = "*.md",
      callback = function()
        local file_path = vim.fn.expand("%:p")
        local notes_dir = vim.fn.expand(config.get("notes_dir"))
        
        if file_path:find(notes_dir, 1, true) == 1 then
          vim.defer_fn(function()
            get_statistics().show_current_stats()
          end, 100)
        end
      end,
    })
  end
end

--- Open today's daily note
---@param opts table|nil Options
function M.open_daily(opts)
  daily.open_daily_note(opts)
end

--- Open general notes
---@param opts table|nil Options
function M.open_general(opts)
  daily.open_general_notes(opts)
end

--- Toggle between daily and general notes
function M.toggle()
  daily.toggle_daily_general()
end

--- List all daily notes
function M.list()
  list.list_daily_notes()
end

--- Search notes
function M.search()
  list.search_notes()
end

--- Show tag picker
function M.tags()
  tags.show_tag_picker()
end

--- Show notes for a specific tag
---@param tag string
function M.by_tag(tag)
  tags.show_notes_for_tag(tag)
end

--- Archive old notes
---@param days number|nil Number of days (uses config if not provided)
function M.archive_old(days)
  days = days or config.get("auto_archive_days") or 90
  archive.archive_old_notes(days)
end

--- Show archived notes
function M.show_archive()
  archive.show_archive_picker()
end

--- Restore a note from archive
---@param path string
function M.restore(path)
  return archive.restore_note(path)
end

--- Export current note (placeholder for future implementation)
---@param format string Format to export to (pdf, html, etc.)
function M.export(format)
  vim.notify("CSNotes: Export functionality coming soon", vim.log.levels.INFO)
  -- Future implementation for PDF/HTML export
end

--- Check if Telescope is available
---@return boolean
function M.has_telescope()
  return pcall(require, "telescope")
end

--- Show statistics for current note
function M.show_stats()
  get_statistics().show_current_stats()
end

--- Show aggregate statistics
function M.show_all_stats()
  get_statistics().show_aggregate_stats()
end

--- Show backlinks for current note
function M.show_backlinks()
  get_linking().show_backlinks()
end

--- Insert a link to another note
---@param note_name string|nil
function M.insert_link(note_name)
  get_linking().insert_link(note_name)
end

--- Follow link under cursor
function M.follow_link()
  get_linking().follow_link()
end

--- Show all links (incoming and outgoing)
function M.show_links()
  get_linking().show_all_links()
end

--- Add tags to current note frontmatter
---@param tags table|string
function M.add_tags(tags)
  local current_file = vim.fn.expand("%:p")
  return get_frontmatter().add_tags(current_file, tags)
end

--- Remove tags from current note frontmatter
---@param tags table|string
function M.remove_tags(tags)
  local current_file = vim.fn.expand("%:p")
  return get_frontmatter().remove_tags(current_file, tags)
end

--- Get metadata for current note
---@return table|nil
function M.get_metadata()
  local current_file = vim.fn.expand("%:p")
  return get_frontmatter().get_metadata(current_file)
end

--- Show task report
---@param options table|nil Options {completed: bool, sort_by: string}
function M.show_tasks(options)
  get_tasks().show_report(options)
end

--- Get all incomplete tasks
---@return table
function M.get_incomplete_tasks()
  return get_tasks().get_incomplete_tasks()
end

--- Get all completed tasks
---@return table
function M.get_completed_tasks()
  return get_tasks().get_completed_tasks()
end

--- Get overdue tasks
---@return table
function M.get_overdue_tasks()
  return get_tasks().get_overdue_tasks()
end

--- Get task statistics
---@return table
function M.get_task_stats()
  return get_tasks().get_statistics()
end

--- Export task report to file
---@param filepath string
---@param options table|nil
---@return boolean
function M.export_task_report(filepath, options)
  return get_tasks().export_report(filepath, options)
end

--- Initialize PARA structure for general notes
---@return boolean success
---@return string|nil error
function M.init_para()
  return get_para().initialize_para()
end

--- Open a PARA category (projects, areas, resources, archive)
---@param category string
---@param opts table|nil
function M.open_para(category, opts)
  get_para().open_category(category, opts)
end

--- Show PARA category picker
function M.para_picker()
  get_para().show_category_picker()
end

--- Get PARA statistics
---@return table
function M.para_stats()
  return get_para().get_para_stats()
end

--- Update PARA dashboard
---@return boolean success
function M.update_para_dashboard()
  return get_para().update_dashboard()
end

return M
