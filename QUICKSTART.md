# CSNotes.nvim Quick Start Guide

Get up and running with CSNotes.nvim in 5 minutes!

## Installation

### Step 1: Install the plugin

Add to your Neovim configuration:

**lazy.nvim:**
```lua
{
  "paulatcodescout/csnotes.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("csnotes").setup()
  end,
}
```

### Step 2: Create notes directory

```bash
mkdir -p ~/notes/daily ~/notes/general ~/notes/archive
```

### Step 3: Load Telescope extension (optional)

Add to your Neovim config:
```lua
require("telescope").load_extension("csnotes")
```

### Step 4: Restart Neovim

```bash
nvim
```

## Basic Usage

### Creating Your First Daily Note

Press `<leader>nd` (or run `:CSNotesDaily`) to create today's note.

You'll see a new note with this template:
```markdown
# Monday, January 23, 2026

## Tasks
- [ ] 

## Notes

```

### Writing Notes

Just start typing! Example:
```markdown
# Monday, January 23, 2026

## Tasks
- [ ] Review pull requests
- [x] Update documentation
- [ ] Team meeting at 2pm

## Notes

Met with the team about the new #project-alpha initiative.
Key takeaways:
- Launch date: February 15
- Need to finalize #design before next week
- #important - Budget approval required

```

### Using Tags

Add tags anywhere with `#tagname`:
- `#work` 
- `#project-alpha`
- `#important`
- `#meeting-notes`

View all tags: `<leader>` then press the tags key or `:CSNotesTags`

### Searching Notes

Search across all notes:
1. Press `<leader>ns` (or run `:CSNotesSearch`)
2. Type your search query
3. Press Enter
4. Select a result to jump to that note

### General Notes

For permanent information that isn't date-specific:
- Press `<leader>ng` to open general notes
- Press `<leader>nt` to toggle between daily and general notes

### Listing All Notes

Press `<leader>nl` (or run `:CSNotesList`) to see all your daily notes.

## Advanced Features

### Telescope Integration

Use Telescope for enhanced navigation:
```vim
:Telescope csnotes daily       " Browse daily notes
:Telescope csnotes search      " Search with preview
:Telescope csnotes tags        " Browse by tags
:Telescope csnotes archive     " View archived notes
```

### Archiving Old Notes

Keep your notes directory clean:
```vim
:CSNotesArchive 90    " Archive notes older than 90 days
:CSNotesShowArchive   " View archived notes
```

Press `r` in the archive picker to restore a note.

### Custom Configuration

Customize in your setup:
```lua
require("csnotes").setup({
  notes_dir = "~/Documents/notes/daily",
  date_format = "%Y%m%d",  -- YYYYMMDD format
  template = [[# {date}

## Morning Review
- 

## Daily Log

## Evening Reflection
]],
  auto_archive_days = 30,  -- Archive after 30 days
})
```

## Example Workflow

### Morning Routine
1. `<leader>nd` - Open today's note
2. Write your daily goals and tasks
3. Add `#tags` for organization

### During the Day
1. `<leader>nd` - Quickly jot down notes
2. `<leader>ns` - Search previous notes when needed
3. `<leader>nt` - Switch to general notes for reference

### End of Day
1. Review and update your daily note
2. Check off completed tasks
3. Add reflection or summary

### Weekly Review
1. `:CSNotesList` - Browse last week's notes
2. `:CSNotesTags` - Review notes by project/topic
3. Archive old notes if needed

## Keyboard Reference

| Key | Action |
|-----|--------|
| `<leader>nd` | Open daily note |
| `<leader>ng` | Open general notes |
| `<leader>nt` | Toggle daily/general |
| `<leader>nl` | List all notes |
| `<leader>ns` | Search notes |
| `<leader>na` | Archive old notes |

## Tips

1. **Use consistent tags** - Helps with filtering later
2. **Daily template** - Customize it to match your workflow
3. **Archive regularly** - Keeps your notes directory fast
4. **Search is powerful** - Find anything across all notes instantly
5. **Telescope integration** - Use it for the best experience

## Troubleshooting

### Notes not saving?
Check that the directory exists:
```bash
ls -la ~/notes/daily
```

### Keybindings not working?
Another plugin might be using the same keys. Customize them:
```lua
require("csnotes").setup({
  mappings = {
    open_daily = "<leader>dn",  -- Change to your preference
  },
})
```

### Telescope not found?
Install telescope.nvim first, or use the built-in pickers.

## Next Steps

- Read the [full README](README.md) for all features
- Check out [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Browse the [help docs](doc/csnotes.txt) with `:help csnotes`

Happy note-taking! 📝
