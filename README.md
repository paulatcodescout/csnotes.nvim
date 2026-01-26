# CSNotes.nvim

A powerful Neovim plugin for capturing and managing daily notes with tagging, search, archiving, and Telescope integration.

## Features

### Core Features
- 📅 **Daily Notes**: Create or open daily notes with a single keybinding
- 📝 **General Notes**: Quick access to a general notes file
- 🏷️ **Tagging System**: Tag your notes with `#tags` and filter by tags
- 🔍 **Search**: Powerful search across all your notes
- 📦 **Archiving**: Automatically archive old notes to keep your workspace clean
- 🔭 **Telescope Integration**: Enhanced note navigation with Telescope
- 💾 **Backup Support**: Optional automatic backups of your notes
- ⚙️ **Customizable**: Flexible configuration for directories, date formats, and templates
- ⚡ **Performance**: Efficient and lightweight, won't slow down Neovim

### Advanced Features (New!)
- 📋 **Frontmatter Support**: YAML frontmatter with metadata (title, created, modified, tags)
- 📊 **Statistics**: Track word count, note count, and writing patterns
- 🔗 **Note Linking**: Wiki-style `[[links]]` with backlinks support
- 🎨 **Template Variables**: Enhanced template system with custom variables
- 🔄 **Auto-Update**: Automatic modified timestamp updates
- ✅ **Task Management**: Track todos across notes with priorities, due dates, and reports

## Requirements

- Neovim >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced search and navigation)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "paulatcodescout/csnotes.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Optional
  },
  config = function()
    require("csnotes").setup({
      -- Your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "paulatcodescout/csnotes.nvim",
  requires = {
    "nvim-telescope/telescope.nvim", -- Optional
  },
  config = function()
    require("csnotes").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-telescope/telescope.nvim'  " Optional
Plug 'paulatcodescout/csnotes.nvim'

lua << EOF
require("csnotes").setup()
EOF
```

## Configuration

Here's the default configuration with all available options:

```lua
require("csnotes").setup({
  -- Directory where daily notes are stored
  notes_dir = "~/notes/daily",
  
  -- Directory for general notes
  general_notes_dir = "~/notes/general",
  
  -- Directory for archived notes
  archive_dir = "~/notes/archive",
  
  -- Date format for filenames (strftime format)
  date_format = "%Y-%m-%d",
  
  -- Date format for note headers
  header_date_format = "%A, %B %d, %Y",
  
  -- Template for new daily notes
  template = [[# {date}

## Tasks
- [ ] 

## Notes

]],
  
  -- General notes filename
  general_notes_file = "general.md",
  
  -- Auto-archive notes older than this many days (0 to disable)
  auto_archive_days = 90,
  
  -- Keybindings (set to false to disable default mappings)
  mappings = {
    open_daily = "<leader>nd",
    open_general = "<leader>ng",
    toggle_daily_general = "<leader>nt",
    list_notes = "<leader>nl",
    search_notes = "<leader>ns",
    archive_old = "<leader>na",
  },
  
  -- Telescope configuration
  telescope = {
    theme = "dropdown",
    previewer = true,
  },
  
  -- Backup configuration
  backup = {
    enabled = false,
    dir = "~/notes/backups",
    on_save = false, -- Backup on save
  },
})
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:CSNotesDaily` | Open or create today's daily note |
| `:CSNotesGeneral` | Open the general notes file |
| `:CSNotesToggle` | Toggle between daily and general notes |
| `:CSNotesList` | List all daily notes in a picker |
| `:CSNotesSearch` | Search across all notes |
| `:CSNotesTags` | Show all tags and filter notes by tag |
| `:CSNotesArchive [days]` | Archive notes older than specified days |
| `:CSNotesShowArchive` | View and restore archived notes |
| `:CSNotesExport [format]` | Export current note (future feature) |

### Default Keybindings

| Keybinding | Action |
|------------|--------|
| `<leader>nd` | Open today's daily note |
| `<leader>ng` | Open general notes |
| `<leader>nt` | Toggle between daily and general notes |
| `<leader>nl` | List all daily notes |
| `<leader>ns` | Search notes |
| `<leader>na` | Archive old notes |

You can customize these keybindings in the setup configuration or disable them by setting `mappings = false`.

### Telescope Integration

If you have Telescope installed, you can use enhanced pickers:

```vim
:Telescope csnotes daily       " Browse daily notes
:Telescope csnotes search      " Search in notes with preview
:Telescope csnotes tags        " Browse and filter by tags
:Telescope csnotes archive     " View archived notes
```

Load the extension in your Telescope configuration:

```lua
require("telescope").load_extension("csnotes")
```

### Tagging Notes

Simply use hashtags anywhere in your notes:

```markdown
# Monday, January 23, 2026

Had a great meeting about the #project-alpha today.
Need to follow up on #tasks for the week.

#important #work
```

Use `:CSNotesTags` or `:Telescope csnotes tags` to browse notes by tag.

### Archiving

Archive old notes automatically or manually:

```lua
-- Archive notes older than 90 days (configured in setup)
:CSNotesArchive

-- Archive notes older than 30 days
:CSNotesArchive 30

-- View archived notes
:CSNotesShowArchive
```

In the archive picker:
- Press `<CR>` or `o` to open an archived note
- Press `r` to restore a note from archive

### Search

Search across all your daily notes:

```vim
:CSNotesSearch
" or
:Telescope csnotes search
```

Results show the filename, line number, and matching content. Press `<CR>` to jump to that location.

### Custom Templates

Customize the template for new notes:

```lua
require("csnotes").setup({
  template = [[# {date}

## 🎯 Goals

## 📝 Notes

## ✅ Completed

## 🔖 Tags
]],
})
```

The `{date}` placeholder will be replaced with the formatted date.

### Custom Date Formats

Use any [strftime format](https://strftime.org/) for dates:

```lua
require("csnotes").setup({
  -- Filename format: 2026-01-23
  date_format = "%Y-%m-%d",
  
  -- Header format: Monday, January 23, 2026
  header_date_format = "%A, %B %d, %Y",
})
```

Examples:
- `%Y-%m-%d` → 2026-01-23
- `%Y%m%d` → 20260123
- `%d-%m-%Y` → 23-01-2026
- `%Y-W%W-%u` → 2026-W04-4 (ISO week date)

### Backup Configuration

Enable automatic backups:

```lua
require("csnotes").setup({
  backup = {
    enabled = true,
    dir = "~/notes/backups",
    on_save = true,
  },
})
```

Backups are timestamped: `2026-01-23_143022.md`

## Lua API

You can use the plugin programmatically:

```lua
local csnotes = require("csnotes")

-- Open today's daily note
csnotes.open_daily()

-- Open in a vertical split
csnotes.open_daily({ split = "vertical" })

-- Open general notes
csnotes.open_general()

-- Toggle between daily and general
csnotes.toggle()

-- List notes
csnotes.list()

-- Search notes
csnotes.search()

-- Show tags
csnotes.tags()

-- Get notes by tag
csnotes.by_tag("project-alpha")

-- Archive notes older than 60 days
csnotes.archive_old(60)

-- Show archived notes
csnotes.show_archive()
```

## Tips and Tricks

### Daily Note Workflow

1. Start your day with `<leader>nd` to open today's note
2. Jot down tasks, meeting notes, and thoughts
3. Use `#tags` to categorize content
4. Use `<leader>ns` to search previous notes when needed
5. Use `<leader>nt` to quickly switch to general notes for permanent information

### Integration with Other Plugins

#### With [which-key.nvim](https://github.com/folke/which-key.nvim)

```lua
local wk = require("which-key")
wk.register({
  ["<leader>n"] = {
    name = "notes",
    d = { "<cmd>CSNotesDaily<cr>", "Daily note" },
    g = { "<cmd>CSNotesGeneral<cr>", "General notes" },
    t = { "<cmd>CSNotesToggle<cr>", "Toggle" },
    l = { "<cmd>CSNotesList<cr>", "List notes" },
    s = { "<cmd>CSNotesSearch<cr>", "Search" },
    T = { "<cmd>CSNotesTags<cr>", "Tags" },
    a = { "<cmd>CSNotesArchive<cr>", "Archive old" },
  },
})
```

#### With markdown preview plugins

CSNotes.nvim works great with markdown preview plugins like:
- [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim)
- [glow.nvim](https://github.com/ellisonleao/glow.nvim)

### Custom Keybindings

Disable default mappings and set your own:

```lua
require("csnotes").setup({
  mappings = false,
})

-- Set your own keybindings
vim.keymap.set("n", "<leader>dd", "<cmd>CSNotesDaily<cr>")
vim.keymap.set("n", "<leader>dg", "<cmd>CSNotesGeneral<cr>")
-- etc.
```

## Roadmap

Features planned for future releases:

- [ ] Export to PDF/HTML
- [ ] Calendar integration
- [ ] Email/messaging integration
- [ ] Note linking and backlinks
- [ ] Cloud sync support (Dropbox, Google Drive, etc.)
- [ ] Reminder/notification system
- [ ] Statistics and insights (word count, notes per day, etc.)
- [ ] Templates per weekday
- [ ] Note encryption support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Clone the repository
2. Make your changes
3. Run tests: `make test`
4. Submit a PR

## Testing

Run the test suite:

```bash
make test
```

## Troubleshooting

### Notes directory not found

Make sure the directories exist or will be created automatically. Check your configuration:

```lua
require("csnotes").setup({
  notes_dir = "~/notes/daily",  -- Make sure this path is correct
})
```

### Telescope integration not working

Make sure Telescope is installed and loaded before CSNotes:

```lua
require("telescope").load_extension("csnotes")
```

### Keybindings not working

Check if another plugin is using the same keybindings. You can customize them in the setup:

```lua
require("csnotes").setup({
  mappings = {
    open_daily = "<leader>dn",  -- Change to avoid conflicts
  },
})
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by various note-taking workflows and tools
- Built with [Neovim](https://neovim.io/) and [Lua](https://www.lua.org/)
- Telescope integration powered by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Support

If you encounter any issues or have questions:

1. Check the [documentation](#usage)
2. Search [existing issues](https://github.com/paulatcodescout/csnotes.nvim/issues)
3. Create a new issue if needed

---

Made with ❤️ for the Neovim community
