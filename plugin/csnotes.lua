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

vim.api.nvim_create_user_command("CSNotesStats", function(opts)
  require("csnotes").show_stats()
end, { desc = "Show statistics for current note" })

vim.api.nvim_create_user_command("CSNotesAllStats", function(opts)
  require("csnotes").show_all_stats()
end, { desc = "Show aggregate statistics for all notes" })

vim.api.nvim_create_user_command("CSNotesBacklinks", function(opts)
  require("csnotes").show_backlinks()
end, { desc = "Show backlinks to current note" })

vim.api.nvim_create_user_command("CSNotesInsertLink", function(opts)
  local note_name = opts.args ~= "" and opts.args or nil
  require("csnotes").insert_link(note_name)
end, { nargs = "?", desc = "Insert link to another note" })

vim.api.nvim_create_user_command("CSNotesFollowLink", function(opts)
  require("csnotes").follow_link()
end, { desc = "Follow link under cursor" })

vim.api.nvim_create_user_command("CSNotesShowLinks", function(opts)
  require("csnotes").show_links()
end, { desc = "Show all links for current note" })

vim.api.nvim_create_user_command("CSNotesAddTags", function(opts)
  if opts.args and opts.args ~= "" then
    local tags = vim.split(opts.args, ",")
    for i, tag in ipairs(tags) do
      tags[i] = vim.trim(tag)
    end
    require("csnotes").add_tags(tags)
    vim.notify("CSNotes: Tags added to frontmatter", vim.log.levels.INFO)
  else
    vim.notify("CSNotes: Please specify tags (comma-separated)", vim.log.levels.WARN)
  end
end, { nargs = "?", desc = "Add tags to note frontmatter" })

vim.api.nvim_create_user_command("CSNotesRemoveTags", function(opts)
  if opts.args and opts.args ~= "" then
    local tags = vim.split(opts.args, ",")
    for i, tag in ipairs(tags) do
      tags[i] = vim.trim(tag)
    end
    require("csnotes").remove_tags(tags)
    vim.notify("CSNotes: Tags removed from frontmatter", vim.log.levels.INFO)
  else
    vim.notify("CSNotes: Please specify tags (comma-separated)", vim.log.levels.WARN)
  end
end, { nargs = "?", desc = "Remove tags from note frontmatter" })

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
