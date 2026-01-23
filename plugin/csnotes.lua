-- Prevent loading the plugin twice
if vim.g.loaded_csnotes then
  return
end
vim.g.loaded_csnotes = true

-- Create commands
vim.api.nvim_create_user_command("CSNotesDaily", function(opts)
  require("csnotes").open_daily()
end, { desc = "Open today's daily note" })

vim.api.nvim_create_user_command("CSNotesGeneral", function(opts)
  require("csnotes").open_general()
end, { desc = "Open general notes" })

vim.api.nvim_create_user_command("CSNotesToggle", function(opts)
  require("csnotes").toggle()
end, { desc = "Toggle between daily and general notes" })

vim.api.nvim_create_user_command("CSNotesList", function(opts)
  require("csnotes").list()
end, { desc = "List all daily notes" })

vim.api.nvim_create_user_command("CSNotesSearch", function(opts)
  require("csnotes").search()
end, { desc = "Search in notes" })

vim.api.nvim_create_user_command("CSNotesTags", function(opts)
  require("csnotes").tags()
end, { desc = "Show all tags" })

vim.api.nvim_create_user_command("CSNotesArchive", function(opts)
  if opts.args and opts.args ~= "" then
    local days = tonumber(opts.args)
    if days then
      require("csnotes").archive_old(days)
    else
      vim.notify("CSNotes: Invalid number of days", vim.log.levels.ERROR)
    end
  else
    require("csnotes").archive_old()
  end
end, { nargs = "?", desc = "Archive old notes (optional: number of days)" })

vim.api.nvim_create_user_command("CSNotesShowArchive", function(opts)
  require("csnotes").show_archive()
end, { desc = "Show archived notes" })

vim.api.nvim_create_user_command("CSNotesExport", function(opts)
  local format = opts.args or "pdf"
  require("csnotes").export(format)
end, { nargs = "?", desc = "Export current note (format: pdf, html)" })

-- Set up default keymappings if not disabled
vim.defer_fn(function()
  local csnotes = require("csnotes")
  local config = require("csnotes.config")
  
  -- Only set up mappings if they haven't been disabled
  local mappings = config.get("mappings")
  if mappings then
    if mappings.open_daily then
      vim.keymap.set("n", mappings.open_daily, function()
        csnotes.open_daily()
      end, { desc = "Open daily note" })
    end
    
    if mappings.open_general then
      vim.keymap.set("n", mappings.open_general, function()
        csnotes.open_general()
      end, { desc = "Open general notes" })
    end
    
    if mappings.toggle_daily_general then
      vim.keymap.set("n", mappings.toggle_daily_general, function()
        csnotes.toggle()
      end, { desc = "Toggle daily/general notes" })
    end
    
    if mappings.list_notes then
      vim.keymap.set("n", mappings.list_notes, function()
        csnotes.list()
      end, { desc = "List daily notes" })
    end
    
    if mappings.search_notes then
      vim.keymap.set("n", mappings.search_notes, function()
        csnotes.search()
      end, { desc = "Search notes" })
    end
    
    if mappings.archive_old then
      vim.keymap.set("n", mappings.archive_old, function()
        csnotes.archive_old()
      end, { desc = "Archive old notes" })
    end
  end
end, 0)
