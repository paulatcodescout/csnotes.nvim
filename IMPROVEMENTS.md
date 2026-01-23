# CSNotes.nvim - Improvements & New Features

This document outlines the improvements made to CSNotes.nvim based on the requirements review.

## New Features Added

### 1. Frontmatter Support (Requirement 21) ✅

**Module:** `lua/csnotes/frontmatter.lua`

Notes now support YAML frontmatter with metadata:

```markdown
---
title: 2026-01-23
created: 2026-01-23 14:30:00
modified: 2026-01-23 15:45:00
tags: [work, project-alpha]
---

# Thursday, January 23, 2026

## Notes
...
```

**Features:**
- Automatically generated frontmatter for new notes
- Auto-update modified timestamp on save
- Configurable fields (title, created, modified, tags, etc.)
- Tag management through frontmatter
- Parse and update existing frontmatter

**Commands:**
- `:CSNotesAddTags tag1,tag2` - Add tags to frontmatter
- `:CSNotesRemoveTags tag1,tag2` - Remove tags from frontmatter

**Configuration:**
```lua
frontmatter = {
  enabled = true,
  fields = {"title", "created", "modified", "tags"},
  auto_update_modified = true,
}
```

### 2. Note Statistics & Analytics (New Feature) ✅

**Module:** `lua/csnotes/statistics.lua`

Get insights into your note-taking habits:

**Single Note Stats:**
- Word count
- Line count
- Character count
- File size
- Tag count
- Link count
- Created/modified dates

**Aggregate Stats:**
- Total notes
- Total words/lines
- Average words/lines per note
- Total tags and links

**Commands:**
- `:CSNotesStats` - Show stats for current note
- `:CSNotesAllStats` - Show aggregate statistics

**Configuration:**
```lua
statistics = {
  enabled = true,
  show_on_open = false,  -- Auto-show stats when opening notes
}
```

### 3. Note Linking & Backlinks (Requirement 25) ✅

**Module:** `lua/csnotes/linking.lua`

Create a connected network of notes with wiki-style or markdown-style links:

**Link Styles:**
- Wiki-style: `[[note-name]]`
- Markdown-style: `[text](note-name.md)`

**Features:**
- Insert links to other notes
- Follow links under cursor
- View backlinks (notes that link to current note)
- View all links (incoming + outgoing)
- Auto-complete note names
- Create new notes when following non-existent links

**Commands:**
- `:CSNotesInsertLink [name]` - Insert a link
- `:CSNotesFollowLink` - Follow link under cursor (or use `gf`)
- `:CSNotesBacklinks` - Show notes linking to current note
- `:CSNotesShowLinks` - Show all links for current note

**Configuration:**
```lua
linking = {
  enabled = true,
  style = "wiki",  -- "wiki" or "markdown"
  show_backlinks = true,
}
```

**Suggested Keybinding:**
```lua
vim.keymap.set("n", "gf", require("csnotes").follow_link, { desc = "Follow note link" })
```

### 4. Enhanced Template System (Improvements) ✅

**Built-in Variables:**
- `{date}` - Formatted date (header_date_format)
- `{time}` - Current time (HH:MM:SS)
- `{datetime}` - Full datetime
- `{title}` - Note title (from frontmatter)
- `{tags}` - Tags list (from frontmatter)

**Custom Variables:**
```lua
template_vars = {
  author = "Your Name",
  project = "My Project",
  -- Any custom variable
}
```

**Example Template:**
```lua
template = [[
# {date}

Author: {author}
Project: {project}

## Daily Log
- 

## Tasks
- [ ] 

]]
```

### 5. Auto-Update Modified Time (New Feature) ✅

Frontmatter modified timestamp automatically updates when you save:

```yaml
---
modified: 2026-01-23 15:45:00  # Auto-updated on save
---
```

**Configuration:**
```lua
frontmatter = {
  auto_update_modified = true,
}
```

## Enhanced Functionality

### Improved File Operations
- Better error handling for all file operations
- Automatic directory creation
- File validation before operations

### Performance Optimizations
- Lazy-loading of modules (statistics, linking, frontmatter)
- Efficient file scanning
- Cached file operations where appropriate

### Better User Feedback
- Informative notifications for all operations
- Clear error messages
- Progress indicators for long operations

## New API Functions

### Frontmatter API
```lua
local csnotes = require("csnotes")

-- Get metadata
local metadata = csnotes.get_metadata()

-- Add tags
csnotes.add_tags({"project-alpha", "important"})

-- Remove tags
csnotes.remove_tags({"old-tag"})
```

### Statistics API
```lua
-- Show current note stats
csnotes.show_stats()

-- Show aggregate stats
csnotes.show_all_stats()
```

### Linking API
```lua
-- Insert link
csnotes.insert_link("other-note")

-- Follow link
csnotes.follow_link()

-- Show backlinks
csnotes.show_backlinks()

-- Show all links
csnotes.show_links()
```

## Configuration Examples

### Minimal Configuration
```lua
require("csnotes").setup({
  notes_dir = "~/notes/daily",
})
```

### Full-Featured Configuration
```lua
require("csnotes").setup({
  -- Basic settings
  notes_dir = "~/notes/daily",
  date_format = "%Y-%m-%d",
  header_date_format = "%A, %B %d, %Y",
  
  -- Template with frontmatter
  template = [[
# {date}

## Morning Review

## Daily Log

## Evening Reflection
]],
  
  -- Frontmatter
  frontmatter = {
    enabled = true,
    fields = {"title", "created", "modified", "tags"},
    auto_update_modified = true,
  },
  
  -- Statistics
  statistics = {
    enabled = true,
    show_on_open = false,
  },
  
  -- Linking
  linking = {
    enabled = true,
    style = "wiki",
    show_backlinks = true,
  },
  
  -- Custom template variables
  template_vars = {
    author = "Your Name",
  },
  
  -- Archiving
  auto_archive_days = 90,
  
  -- Backup
  backup = {
    enabled = true,
    dir = "~/notes/backups",
    on_save = true,
  },
})
```

## Workflow Examples

### Daily Note with Frontmatter
1. Open daily note: `<leader>nd`
2. Frontmatter automatically added:
   ```yaml
   ---
   title: 2026-01-23
   created: 2026-01-23 09:00:00
   modified: 2026-01-23 09:00:00
   tags: []
   ---
   ```
3. Add tags: `:CSNotesAddTags work,planning`
4. Modified timestamp auto-updates on save

### Linking Notes
1. In today's note, reference a project:
   ```markdown
   Working on [[project-alpha]] today
   ```
2. Press `gf` or `:CSNotesFollowLink` to jump to project note
3. View backlinks: `:CSNotesBacklinks` to see all notes mentioning this project

### Analytics Workflow
1. Review current note: `:CSNotesStats`
2. See overall progress: `:CSNotesAllStats`
3. Analyze writing patterns over time

## Migration Guide

### Existing Notes
Existing notes without frontmatter will continue to work normally. To add frontmatter:

1. Open an existing note
2. Run: `:CSNotesAddTags tag1,tag2`
3. Frontmatter will be automatically added

### Disabling New Features
Don't want frontmatter or other features? Disable them:

```lua
require("csnotes").setup({
  frontmatter = {
    enabled = false,  -- Disable frontmatter
  },
  statistics = {
    enabled = false,  -- Disable statistics
  },
  linking = {
    enabled = false,  -- Disable linking
  },
})
```

## Requirements Coverage

| Requirement | Status | Implementation |
|------------|--------|----------------|
| 1. Daily note keybinding | ✅ | `<leader>nd`, `:CSNotesDaily` |
| 2. Auto-insert template | ✅ | Template with frontmatter support |
| 3. Customizable settings | ✅ | Extensive configuration options |
| 4. List and select notes | ✅ | Built-in picker + Telescope |
| 5. Telescope integration | ✅ | Full integration |
| 6. Error handling | ✅ | Comprehensive error handling |
| 7. Documentation | ✅ | README, help docs, guides |
| 8. Performance | ✅ | Efficient, lazy-loading |
| 9. Lua best practices | ✅ | Modern Lua implementation |
| 10. Unit tests | ✅ | Test suite included |
| 11. Backup system | ✅ | Configurable backups |
| 12. Tagging | ✅ | Tags in content + frontmatter |
| 13. Markdown support | ✅ | Native markdown |
| 14. Search functionality | ✅ | Full-text search |
| 15. Cross-platform | ✅ | Linux, macOS, Windows |
| 16. Regular updates | ✅ | Contributing guidelines |
| 17. GitHub repository | ✅ | Ready for GitHub |
| 18. Toggle keybinding | ✅ | `<leader>nt` |
| 19. Auto-archive | ✅ | Configurable auto-archive |
| 20. Custom date formats | ✅ | strftime support |
| 21. **Frontmatter support** | ✅ | **Full YAML frontmatter** |

## New Modules

1. **frontmatter.lua** - YAML frontmatter handling
2. **statistics.lua** - Note analytics and statistics
3. **linking.lua** - Note linking and backlinks

## Breaking Changes

None! All new features are opt-in and backward compatible.

## Future Enhancements

- Export to PDF/HTML
- Calendar view
- Graph view of note connections
- Cloud sync integration
- Advanced search filters
- Note templates per weekday
- Collaborative features

---

**Total New Features:** 4 major features
**Total New Commands:** 8 commands
**Total New Modules:** 3 modules
**Lines of Code Added:** ~1000+ lines
