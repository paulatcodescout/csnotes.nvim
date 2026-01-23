local config = require("csnotes.config")
local daily = require("csnotes.daily")
local list = require("csnotes.list")
local tags = require("csnotes.tags")
local archive = require("csnotes.archive")

local M = {}

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
  
  -- Set up autocommands for backup on save
  if config.get("backup.enabled") and config.get("backup.on_save") then
    local group = vim.api.nvim_create_augroup("CSNotesBackup", { clear = true })
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

return M
