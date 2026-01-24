# Implementation Summary: Requirements 23-25

## Overview

This document summarizes the implementation of requirements 23, 24, and 25 from the requirements.txt file.

## Item 23: Linking and Backlinking Support for All Note Types

### Changes Made

**File: `lua/csnotes/linking.lua`**
- Added `get_all_notes()` function that searches both daily notes and general notes directories
- Updated `get_backlinks()` to use the new function, enabling backlink detection across all note types
- Modified `open_linked_note()` to search for notes in both daily and general directories
- Added user prompt to choose where to create a note if it doesn't exist (daily or general)

### Features
- Links work bidirectionally between daily notes and general notes
- Backlinks are detected across all note types
- When following a link to a non-existent note, users can choose where to create it
- Supports both wiki-style `[[note]]` and markdown-style `[text](note.md)` links

### Usage
- Use existing commands: `CSNotesFollowLink`, `CSNotesBacklinks`, `CSNotesShowLinks`
- Use API: `require("csnotes").follow_link()`, `require("csnotes").show_backlinks()`

---

## Item 24: Archive Feature Default to 0 Days

### Changes Made

**File: `lua/csnotes/config.lua`**
- Changed `auto_archive_days` default from `90` to `0`
- This disables auto-archiving by default while still allowing users to customize

### Behavior
- Auto-archiving is now **disabled by default** (0 days)
- Users can enable it by setting `auto_archive_days` to a positive number in their config
- Manual archiving is still available via `CSNotesArchive` command

### Configuration Example
```lua
require("csnotes").setup({
  auto_archive_days = 30,  -- Enable auto-archive after 30 days
})
```

---

## Item 25: PARA Method for General Notes

### Changes Made

**New File: `lua/csnotes/para.lua`**
- Complete PARA (Projects, Areas, Resources, Archive) implementation
- Functions for initializing, managing, and navigating PARA structure
- Dashboard generation with automatic links to all PARA categories
- Statistics and status tracking for PARA notes

**File: `lua/csnotes/daily.lua`**
- Updated `open_general_notes()` to initialize PARA structure on first use
- Dashboard (general.md) now serves as the central hub for PARA navigation

**File: `lua/csnotes/init.lua`**
- Added PARA-related API functions:
  - `init_para()` - Initialize PARA structure
  - `open_para(category)` - Open specific PARA category
  - `para_picker()` - Show category picker
  - `para_stats()` - Get PARA statistics
  - `update_para_dashboard()` - Refresh dashboard

**File: `plugin/csnotes.lua`**
- Added user commands:
  - `CSNotesInitPara` - Initialize PARA structure
  - `CSNotesParaPicker` - Show category picker
  - `CSNotesProjects` - Open Projects
  - `CSNotesAreas` - Open Areas
  - `CSNotesResources` - Open Resources
  - `CSNotesParaArchive` - Open Archive
  - `CSNotesUpdateDashboard` - Update dashboard

**New File: `tests/para_spec.lua`**
- Comprehensive test suite for PARA functionality

### PARA Structure

When `CSNotesGeneral` is run for the first time, it creates:

```
~/notes/general/
├── general.md       # Dashboard with links to all categories
├── projects.md      # Short-term efforts with goals
├── areas.md         # Ongoing responsibilities
├── resources.md     # Reference materials
└── archive.md       # Completed/inactive items
```

### Dashboard Features
- Quick links to all PARA categories
- PARA method overview and documentation
- Recent activity tracking
- Last updated timestamp

### Templates

Each PARA category comes with a pre-configured template:

- **Projects**: Goal, deadline, status, next action tracking
- **Areas**: Personal development, health, relationships, finance, career
- **Resources**: Learning resources, documentation, guides, references
- **Archive**: Organized sections for archived projects, areas, and resources

### Usage

```vim
" Open general notes (shows dashboard)
:CSNotesGeneral

" Or use specific PARA categories
:CSNotesProjects
:CSNotesAreas
:CSNotesResources
:CSNotesParaArchive

" Show category picker
:CSNotesParaPicker

" Update dashboard manually
:CSNotesUpdateDashboard
```

```lua
-- Lua API
local csnotes = require("csnotes")

-- Initialize PARA structure
csnotes.init_para()

-- Open specific category
csnotes.open_para("projects")

-- Get statistics
local stats = csnotes.para_stats()
```

---

## Integration

All three features work together seamlessly:

1. **Linking** works across daily notes, general notes, and all PARA categories
2. **Auto-archive** is disabled by default but can be enabled per user preference
3. **PARA structure** provides organized general notes with a dashboard hub

## Testing

Run the test suite:
```bash
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

---

## Files Modified/Created

### Modified
- `lua/csnotes/config.lua` - Changed archive default
- `lua/csnotes/linking.lua` - Added all-notes support
- `lua/csnotes/daily.lua` - PARA initialization
- `lua/csnotes/init.lua` - PARA API functions
- `plugin/csnotes.lua` - PARA commands

### Created
- `lua/csnotes/para.lua` - Complete PARA implementation
- `tests/para_spec.lua` - PARA test suite
- `IMPLEMENTATION_SUMMARY.md` - This document
