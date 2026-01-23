# Task Management in CSNotes.nvim

CSNotes.nvim includes a powerful task tracking system that helps you manage todos across all your daily notes.

## Features

- ✅ **Extract tasks** from all daily notes
- 🎯 **Priority levels** with visual indicators
- 📅 **Due dates** with overdue detection
- 🏷️ **Tag filtering** for task categories
- 📊 **Statistics** and completion tracking
- 📝 **Task reports** in multiple formats
- 🔍 **Quick navigation** to task locations

## Task Syntax

### Basic Task
```markdown
- [ ] This is an incomplete task
- [x] This is a completed task
```

### Priority Levels
Add `!` markers at the beginning of the task text:

```markdown
- [ ] !!! High priority task (urgent)
- [ ] !! Medium priority task (important)
- [ ] ! Low priority task (when you have time)
- [ ] No priority marker (normal)
```

### Due Dates
Add `@due:YYYY-MM-DD` anywhere in the task:

```markdown
- [ ] Submit report @due:2026-01-25
- [ ] ! Review PR @due:2026-01-24 #work
```

### Tags
Use hashtags to categorize tasks:

```markdown
- [ ] Fix bug in authentication #bug #urgent
- [ ] Update documentation #docs #low-priority
- [ ] Call client @due:2026-01-23 #meetings
```

### Complete Example
```markdown
# Daily Note 2026-01-23

## Tasks
- [ ] !!! Fix production bug @due:2026-01-23 #urgent #bug
- [ ] !! Review pull requests #work #code-review
- [ ] ! Update README documentation #docs
- [ ] Plan next week's sprint #planning
- [x] Daily standup meeting #meetings
```

## Commands

### Show Tasks

| Command | Description |
|---------|-------------|
| `:CSNotesTasks` | Show all incomplete tasks (sorted by priority) |
| `:CSNotesTasksAll` | Show all tasks (completed and incomplete) |
| `:CSNotesTasksCompleted` | Show only completed tasks |
| `:CSNotesTasksOverdue` | Show overdue tasks |
| `:CSNotesTaskStats` | Display task statistics |
| `:CSNotesTaskExport [file]` | Export task report to file |

### Usage Examples

```vim
" Show incomplete tasks
:CSNotesTasks

" View what you've accomplished
:CSNotesTasksCompleted

" Check if anything is overdue
:CSNotesTasksOverdue

" See your task completion rate
:CSNotesTaskStats

" Export incomplete tasks to a file
:CSNotesTaskExport ~/tasks-report.md
```

## Task Report UI

When you run `:CSNotesTasks`, you'll see an interactive report:

```
📋 Task Report

Total: 15 tasks | Status: Incomplete | Sort: priority
────────────────────────────────────────────────────────────────

1. [ ] 🔴 Fix production bug [⚠️ OVERDUE: 2026-01-22] #urgent #bug
   📄 2026-01-22.md:15

2. [ ] 🔴 Submit quarterly report [📅 2026-01-25]
   📄 2026-01-23.md:8

3. [ ] 🟡 Review pull requests #work
   📄 2026-01-23.md:10

4. [ ] 🟢 Update documentation #docs
   📄 2026-01-23.md:12

5. [ ] Plan meeting agenda
   📄 2026-01-23.md:14
```

### Keybindings in Report

- `<Enter>` - Jump to task in note
- `q` or `<Esc>` - Close report
- `?` - Show help

## API Usage

### Programmatic Access

```lua
local csnotes = require("csnotes")

-- Get incomplete tasks
local incomplete = csnotes.get_incomplete_tasks()
for _, task in ipairs(incomplete) do
  print(string.format("%s (Priority: %s)", task.text, task.priority))
end

-- Get completed tasks
local completed = csnotes.get_completed_tasks()
print(string.format("Completed: %d tasks", #completed))

-- Get overdue tasks
local overdue = csnotes.get_overdue_tasks()
if #overdue > 0 then
  print("⚠️ You have overdue tasks!")
end

-- Get statistics
local stats = csnotes.get_task_stats()
print(string.format("Completion rate: %d%%", stats.completion_rate))

-- Show custom task report
csnotes.show_tasks({
  completed = false,
  sort_by = "due_date",  -- "priority", "due_date", "date", "file"
})

-- Export report
csnotes.export_task_report("~/my-tasks.md", {
  completed = false,
  sort_by = "priority",
  format = "markdown",  -- "markdown" or "text"
})
```

### Task Object Structure

```lua
{
  line = 15,                    -- Line number in file
  text = "Fix production bug",  -- Task description
  completed = false,            -- Completion status
  priority = "high",            -- "high", "medium", "low", "none"
  due_date = "2026-01-25",     -- Due date (or nil)
  tags = {"urgent", "bug"},    -- Array of tags
  indent_level = 0,            -- Indentation level
  file = "/path/to/note.md",   -- Full file path
  filename = "2026-01-23.md",  -- Filename only
  note_date = "2026-01-23",    -- Date from filename
  note_timestamp = 1234567890  -- Unix timestamp
}
```

## Task Statistics

Get comprehensive statistics:

```lua
local stats = csnotes.get_task_stats()
-- Returns:
{
  total = 20,              -- Total tasks
  completed = 12,          -- Completed tasks
  incomplete = 8,          -- Incomplete tasks
  overdue = 2,            -- Overdue tasks
  completion_rate = 60,    -- Percentage
  by_priority = {
    high = 2,
    medium = 3,
    low = 2,
    none = 1
  }
}
```

## Filtering Tasks

### By Status
```lua
-- Only incomplete
csnotes.show_tasks({ completed = false })

-- Only completed
csnotes.show_tasks({ completed = true })

-- All tasks
csnotes.show_tasks({})
```

### By Priority
```lua
local tasks = require("csnotes.tasks")
local high_priority = tasks.get_all_tasks({ 
  completed = false,
  priority = "high" 
})
```

### By Tags
```lua
local tasks = require("csnotes.tasks")
local work_tasks = tasks.get_all_tasks({
  completed = false,
  tags = {"work"}
})
```

### Overdue Only
```lua
local tasks = require("csnotes.tasks")
local overdue = tasks.get_all_tasks({
  completed = false,
  overdue = true
})
```

## Sorting Options

Sort tasks by different criteria:

```lua
csnotes.show_tasks({ 
  sort_by = "priority"  -- High priority first
})

csnotes.show_tasks({ 
  sort_by = "due_date"  -- Soonest due date first
})

csnotes.show_tasks({ 
  sort_by = "date"      -- Most recent note first
})

csnotes.show_tasks({ 
  sort_by = "file"      -- Alphabetical by filename
})
```

## Export Formats

### Markdown Format
```markdown
# Task Report

Generated: 2026-01-23 14:30:00
Total tasks: 15

## 2026-01-23.md

- [ ] !!! Fix production bug @due:2026-01-23 #urgent #bug
- [ ] !! Review pull requests #work
- [ ] Update documentation

## 2026-01-22.md

- [ ] ! Plan next sprint #planning
```

### Text Format
```
Task Report
================================================================================
Generated: 2026-01-23 14:30:00
Total tasks: 15

[ ] 🔴 Fix production bug (Due: 2026-01-23)
    File: 2026-01-23.md (line 15)

[ ] 🟡 Review pull requests
    File: 2026-01-23.md (line 18)
```

## Best Practices

### 1. Consistent Syntax
Use consistent task syntax across all notes:
```markdown
- [ ] Task description @due:YYYY-MM-DD #tag1 #tag2
```

### 2. Priority Guidelines
- `!!!` - Must be done today, blocks other work
- `!!` - Important, should be done soon
- `!` - Nice to have, when time permits
- No marker - Regular task

### 3. Due Dates
Always use ISO format: `@due:YYYY-MM-DD`
```markdown
- [ ] Task @due:2026-01-25  ✓ Good
- [ ] Task @due:01/25/2026  ✗ Bad
```

### 4. Meaningful Tags
Use tags for categories, not priorities:
```markdown
- [ ] !!! Fix login bug #bug #urgent       ✓ Good
- [ ] Fix login bug #high-priority #bug    ✗ Use ! markers instead
```

### 5. Regular Reviews
Run these commands regularly:
```vim
:CSNotesTasksOverdue  " Daily
:CSNotesTaskStats     " Weekly
:CSNotesTasks         " Throughout the day
```

## Workflow Examples

### Morning Review
```vim
" Check what's overdue
:CSNotesTasksOverdue

" View all incomplete tasks
:CSNotesTasks

" See overall progress
:CSNotesTaskStats
```

### Weekly Planning
```vim
" Review completed work
:CSNotesTasksCompleted

" Export incomplete tasks for next week
:CSNotesTaskExport ~/tasks-next-week.md

" Check completion rate
:CSNotesTaskStats
```

### Project-Specific
```lua
-- Find all tasks for a specific project
local tasks = require("csnotes.tasks")
local project_tasks = tasks.get_all_tasks({
  completed = false,
  tags = {"project-alpha"}
})
```

## Integration with Other Features

### Frontmatter Tags
Tasks tags automatically sync with note frontmatter:
```yaml
---
tags: [work, urgent, bug]
---

- [ ] Fix production bug #work #urgent #bug
```

### Statistics
Task completion contributes to your note statistics:
```vim
:CSNotesStats        " Shows tasks in current note
:CSNotesAllStats     " Includes task counts
```

### Search
Find tasks with search:
```vim
:CSNotesSearch [ ]   " Find incomplete tasks
:CSNotesSearch !!!   " Find high priority tasks
```

## Tips & Tricks

### 1. Quick Task Entry
Create a snippet for task templates:
```lua
vim.keymap.set("i", "<C-t>", "- [ ] ", { desc = "Insert task" })
```

### 2. Custom Report Command
```vim
command! TasksToday lua require("csnotes.tasks").show_report({
  completed = false,
  sort_by = "priority"
})
```

### 3. Status Line Integration
Show incomplete task count in status line:
```lua
local function task_count()
  local tasks = require("csnotes").get_incomplete_tasks()
  return string.format("☐ %d", #tasks)
end
```

### 4. Daily Task Summary
Add to your daily template:
```markdown
## Tasks Summary
<!-- Run :CSNotesTasks to see all incomplete tasks -->
```

## Troubleshooting

### Tasks Not Showing Up

Check your syntax:
```markdown
✓ - [ ] Task            " Good: space in brackets"
✗ - [] Task             " Bad: no space"
✗ - [  ] Task           " Bad: extra space"
✓ - [x] Task            " Good: completed"
✓ - [X] Task            " Good: completed (uppercase)"
```

### Priority Not Recognized

Priority markers must be at the start of task text:
```markdown
✓ - [ ] !!! Important task
✗ - [ ] Important !!! task
```

### Due Date Not Parsing

Use ISO format only:
```markdown
✓ @due:2026-01-25
✗ @due: 2026-01-25    " No space after colon"
✗ @due:01-25-2026     " Wrong order"
```

## Future Enhancements

Planned features:
- [ ] Recurring tasks
- [ ] Task dependencies
- [ ] Time tracking
- [ ] Calendar view
- [ ] Task notifications
- [ ] Gantt chart view
- [ ] Task templates

---

For more information, see:
- [README.md](README.md) - Main documentation
- [IMPROVEMENTS.md](IMPROVEMENTS.md) - All new features
- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
