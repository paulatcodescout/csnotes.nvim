# Linking System Improvements

## Overview

The linking system has been significantly improved to handle various link formats and edge cases more robustly.

## Changes Made

### 1. Wiki-Style Links with Pipe Syntax (`[[note|alternative text]]`)

**Previous Behavior:**
- Only supported simple wiki links: `[[note-name]]`
- Pipe syntax `[[note|text]]` was not recognized
- Would fail to follow links with alternative text

**New Behavior:**
- ✅ Supports both `[[note-name]]` and `[[note-name|Alternative Text]]`
- ✅ Extracts the note name (part before `|`) for linking
- ✅ Ignores alternative text when following links
- ✅ Properly finds backlinks even when pipe syntax is used

**Examples:**
```markdown
[[projects]]                    → Opens projects.md
[[projects|My Projects]]        → Opens projects.md (ignores "My Projects")
[[2023-01-15|Daily Note]]       → Opens 2023-01-15.md
```

### 2. Links Without .md Extension

**Previous Behavior:**
- Required `.md` extension in markdown-style links
- `[text](note)` would not work correctly

**New Behavior:**
- ✅ Supports both `[text](note.md)` and `[text](note)`
- ✅ Automatically handles extension stripping
- ✅ Searches for notes with or without extension

**Examples:**
```markdown
[My Project](projects.md)       → Opens projects.md
[My Project](projects)          → Opens projects.md
[[projects]]                    → Opens projects.md
```

### 3. Improved Pattern Matching and Escaping

**Previous Behavior:**
- Used simple pattern escaping (`gsub("%-", "%%-")`)
- Could fail with note names containing special characters
- Cursor position detection was basic

**New Behavior:**
- ✅ Comprehensive pattern character escaping
- ✅ Handles note names with: `-`, `_`, numbers, spaces (in pipe syntax)
- ✅ Improved cursor position detection for links
- ✅ Whitespace trimming for note names

**Supported Special Characters:**
```markdown
[[my-note-2023]]               → Works
[[note_with_underscore]]       → Works
[[my note | Alternative Text]] → Works (whitespace trimmed)
```

### 4. Enhanced Backlink Detection

**Previous Behavior:**
- Simple pattern matching for backlinks
- Didn't handle all link variations
- Could miss links with special characters

**New Behavior:**
- ✅ Detects backlinks from all link formats
- ✅ Handles wiki links with and without pipes
- ✅ Handles markdown links with and without `.md`
- ✅ Properly escapes special characters in search patterns

### 5. Cross-Directory Linking

**Enhancement:**
- ✅ Links work between daily notes and general notes
- ✅ Links work between all PARA categories
- ✅ When creating a new linked note, prompts for location (daily or general)

## Files Modified

1. **`lua/csnotes/linking.lua`**
   - Updated `follow_link()` to handle pipe syntax and missing extensions
   - Improved pattern matching with comprehensive escaping
   - Enhanced backlink search patterns

2. **`lua/csnotes/utils.lua`**
   - Updated `extract_links()` to parse pipe syntax
   - Added whitespace trimming
   - Improved markdown link extraction

3. **`lua/csnotes/para.lua`**
   - Fixed dashboard wiki-link format (removed incorrect pipe usage)

4. **`tests/linking_spec.lua`** (new)
   - Comprehensive test suite for all link formats
   - Tests for pipe syntax, extensions, backlinks
   - Edge case coverage

## Link Format Reference

### Supported Link Formats

| Format | Example | Behavior |
|--------|---------|----------|
| Simple wiki link | `[[note-name]]` | Opens note-name.md |
| Wiki link with alt text | `[[note-name\|Display Text]]` | Opens note-name.md, ignores display text |
| Markdown with extension | `[Display](note-name.md)` | Opens note-name.md |
| Markdown without extension | `[Display](note-name)` | Opens note-name.md |

### What Gets Extracted for Linking

```markdown
[[projects]]                    → "projects"
[[projects|My Projects]]        → "projects" (pipe text ignored)
[Link](projects.md)             → "projects" (.md stripped)
[Link](projects)                → "projects"
[[my-note-2023]]                → "my-note-2023"
[[note | Spaced Text ]]         → "note" (whitespace trimmed)
```

## Commands and Usage

### Following Links
- Place cursor on or inside a link
- Run `:CSNotesFollowLink` or `gf` (if mapped)
- Works with any supported link format

### Viewing Backlinks
- Open a note
- Run `:CSNotesBacklinks`
- Shows all notes that link to the current note
- Includes links in all supported formats

### Inserting Links
- Run `:CSNotesInsertLink note-name`
- Or `:CSNotesInsertLink` for interactive prompt
- Uses configured style (wiki or markdown)

### Viewing All Links
- Run `:CSNotesShowLinks`
- Shows both outgoing links and backlinks
- Displays in a floating window

## Testing

Run the linking test suite:
```bash
nvim --headless -c "PlenaryBustedFile tests/linking_spec.lua {minimal_init = 'tests/minimal_init.lua'}"
```

## Migration Notes

### For Existing Users

All existing links will continue to work. The improvements are backward compatible:
- Simple wiki links `[[note]]` work as before
- Simple markdown links work as before
- New formats are now also supported

### Recommended Link Format

For maximum flexibility, we recommend:
- **Wiki links**: Use `[[note-name]]` for simple links
- **Wiki links with alt text**: Use `[[note-name|Display Text]]` when you want different display text
- **Cross-references**: Both formats work equally well across daily notes and PARA categories

## Known Limitations

1. **URL Links**: External URLs in markdown format `[text](https://...)` are extracted by `extract_links()` but will fail when attempting to open. This is expected behavior.

2. **Relative Paths**: Links using relative paths like `[text](../other/note.md)` are not currently supported. Links should use simple note names only.

3. **Case Sensitivity**: Note names are case-sensitive. `[[Note]]` and `[[note]]` are different.

## Future Enhancements

Potential improvements for future versions:
- Auto-completion for note names when inserting links
- Link validation (warn about broken links)
- Bulk link updates when renaming notes
- Visual indication of linked vs. unlinked references
