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

-- Task management commands
vim.api.nvim_create_user_command("CSNotesTasks", function(opts)
  require("csnotes").show_tasks({ completed = false, sort_by = "priority" })
end, { desc = "Show incomplete tasks from all notes" })

vim.api.nvim_create_user_command("CSNotesTasksAll", function(opts)
  require("csnotes").show_tasks({ sort_by = "priority" })
end, { desc = "Show all tasks (completed and incomplete)" })

vim.api.nvim_create_user_command("CSNotesTasksCompleted", function(opts)
  require("csnotes").show_tasks({ completed = true, sort_by = "date" })
end, { desc = "Show completed tasks" })

vim.api.nvim_create_user_command("CSNotesTasksOverdue", function(opts)
  local tasks = require("csnotes").get_overdue_tasks()
  if #tasks == 0 then
    vim.notify("CSNotes: No overdue tasks", vim.log.levels.INFO)
  else
    require("csnotes").show_tasks({ completed = false, sort_by = "due_date" })
  end
end, { desc = "Show overdue tasks" })

vim.api.nvim_create_user_command("CSNotesTaskStats", function(opts)
  local stats = require("csnotes").get_task_stats()
  local lines = {
    "📊 Task Statistics",
    "",
    string.format("Total Tasks: %d", stats.total),
    string.format("✓ Completed: %d", stats.completed),
    string.format("○ Incomplete: %d", stats.incomplete),
    string.format("⚠️  Overdue: %d", stats.overdue),
    string.format("📈 Completion Rate: %d%%", stats.completion_rate),
    "",
    "By Priority:",
    string.format("  🔴 High: %d", stats.by_priority.high),
    string.format("  🟡 Medium: %d", stats.by_priority.medium),
    string.format("  🟢 Low: %d", stats.by_priority.low),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Show task statistics" })

vim.api.nvim_create_user_command("CSNotesTaskExport", function(opts)
  local filepath = opts.args ~= "" and opts.args or vim.fn.expand("~/notes/task-report.md")
  require("csnotes").export_task_report(filepath, { 
    completed = false, 
    sort_by = "priority", 
    format = "markdown" 
  })
end, { nargs = "?", desc = "Export task report to file" })

vim.api.nvim_create_user_command("CSNotesTaskToggle", function(opts)
  require("csnotes").toggle_task()
end, { desc = "Toggle task completion on current line" })

-- PARA method commands
vim.api.nvim_create_user_command("CSNotesInitPara", function(opts)
  local ok, err = require("csnotes").init_para()
  if ok then
    vim.notify("CSNotes: PARA structure initialized", vim.log.levels.INFO)
  else
    vim.notify("CSNotes: " .. (err or "Failed to initialize PARA"), vim.log.levels.ERROR)
  end
end, { desc = "Initialize PARA structure for general notes" })

vim.api.nvim_create_user_command("CSNotesParaPicker", function(opts)
  require("csnotes").para_picker()
end, { desc = "Show PARA category picker" })

vim.api.nvim_create_user_command("CSNotesProjects", function(opts)
  require("csnotes").open_para("projects")
end, { desc = "Open Projects (PARA)" })

vim.api.nvim_create_user_command("CSNotesAreas", function(opts)
  require("csnotes").open_para("areas")
end, { desc = "Open Areas of Responsibility (PARA)" })

vim.api.nvim_create_user_command("CSNotesResources", function(opts)
  require("csnotes").open_para("resources")
end, { desc = "Open Resources (PARA)" })

vim.api.nvim_create_user_command("CSNotesParaArchive", function(opts)
  require("csnotes").open_para("archive")
end, { desc = "Open Archive (PARA)" })

vim.api.nvim_create_user_command("CSNotesUpdateDashboard", function(opts)
  local ok = require("csnotes").update_para_dashboard()
  if ok then
    vim.notify("CSNotes: Dashboard updated", vim.log.levels.INFO)
  else
    vim.notify("CSNotes: Failed to update dashboard", vim.log.levels.ERROR)
  end
end, { desc = "Update PARA dashboard" })

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
    
    if mappings.toggle_task then
      vim.keymap.set("n", mappings.toggle_task, function()
        csnotes.toggle_task()
      end, { desc = "Toggle task completion", buffer = false })
    end
  end
end, 0)
