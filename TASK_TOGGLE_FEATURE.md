# Task Toggle Feature

## Overview

A new feature to quickly toggle task completion status with a keybinding. Press a key while the cursor is on a task line to mark it complete or incomplete.

## Features

- ✅ Toggle tasks between `[ ]` (incomplete) and `[x]` (complete)
- ✅ Works with indented tasks
- ✅ Preserves task metadata (priority, due dates, tags)
- ✅ Handles both lowercase `[x]` and uppercase `[X]`
- ✅ Provides user feedback on toggle action
- ✅ Configurable keybinding

## Usage

### Default Keybinding

**`<leader>nx`** - Toggle task completion on current line

### Commands

```vim
:CSNotesTaskToggle
```

Toggles the task on the current line between complete and incomplete.

### API

```lua
-- Toggle task on current line
require("csnotes").toggle_task()

-- Toggle task on specific buffer and line
require("csnotes.tasks").toggle_task_completion(bufnr, line_num)
```

## Examples

### Basic Usage

Place your cursor on any task line and press `<leader>nx`:

**Before:**
```markdown
- [ ] Write documentation
```

**After:**
```markdown
- [x] Write documentation
```

Press again to toggle back:
```markdown
- [ ] Write documentation
```

### With Task Metadata

Task metadata is preserved when toggling:

```markdown
- [ ] !!! High priority task @due:2024-12-31 #important
```

After toggle:
```markdown
- [x] !!! High priority task @due:2024-12-31 #important
```

### Indented Tasks

Works with nested/indented tasks:

```markdown
- [ ] Parent task
  - [ ] Child task
    - [ ] Grandchild task
```

Cursor on any line and press `<leader>nx` to toggle that specific task.

### Mixed Content

Works in notes with mixed content:

```markdown
# Daily Note 2024-01-26

## Tasks
- [ ] Review pull requests
- [x] Write tests
- [ ] Update documentation

## Notes
Some important notes here

## Meeting Notes
- Not a task, just a bullet point
```

Only lines with `- [ ]` or `- [x]` will be toggled.

## Configuration

### Custom Keybinding

```lua
require("csnotes").setup({
  mappings = {
    toggle_task = "<C-t>",  -- Use Ctrl+t instead
    -- or set to false to disable default mapping
    toggle_task = false,
  },
})
```

### Set Your Own Keybinding

```lua
-- In your init.lua or after calling setup()
vim.keymap.set("n", "<C-x>", function()
  require("csnotes").toggle_task()
end, { desc = "Toggle task completion" })
```

### Disable Auto-mapping

```lua
require("csnotes").setup({
  mappings = {
    toggle_task = false,  -- No default mapping
  },
})
```

## Task Format

The toggle function recognizes these task patterns:

```markdown
- [ ] Task          ✓ Incomplete task
- [x] Task          ✓ Complete task (lowercase)
- [X] Task          ✓ Complete task (uppercase)
  - [ ] Indented    ✓ Indented task
    - [ ] More      ✓ Deeply nested task
- Not a task        ✗ Not recognized (no checkbox)
* [ ] Task          ✗ Not recognized (uses * instead of -)
```

## Feedback Messages

When toggling, you'll see a notification:

- **"Task marked as complete ✓"** - When marking incomplete → complete
- **"Task marked as incomplete"** - When marking complete → incomplete  
- **"No task found on current line"** - When cursor is not on a task line

## Integration with Task Reports

Tasks toggled this way are immediately reflected in:

- `:CSNotesTasks` - Task report
- `:CSNotesTaskStats` - Task statistics
- Task completion percentage calculations

## Technical Details

### How It Works

1. Gets the current line from the buffer
2. Checks if the line matches a task pattern
3. Replaces `[ ]` with `[x]` or vice versa
4. Updates the buffer (doesn't write to file until you save)
5. Shows a notification

### Buffer vs File Operations

The toggle function updates the **buffer content** only. Changes aren't saved to disk until you save the file (`:w`). This means:

- ✅ Fast - No disk I/O
- ✅ Undo-able - Use `u` to undo toggle
- ✅ Safe - Can discard changes with `:q!`

## Testing

Run the test suite:

```bash
nvim --headless -c "PlenaryBustedFile tests/tasks_toggle_spec.lua {minimal_init = 'tests/minimal_init.lua'}"
```

Tests cover:
- Incomplete → complete
- Complete → incomplete
- Uppercase [X] handling
- Indented tasks
- Task metadata preservation
- Non-task lines (should not toggle)
- Multiple toggles
- Mixed content

## Workflow Example

Typical workflow for managing tasks:

1. **Create daily note**: `:CSNotesDaily`

2. **Add tasks**:
   ```markdown
   ## Tasks
   - [ ] Review code
   - [ ] Write tests
   - [ ] Deploy to staging
   ```

3. **Complete tasks**: Move cursor to each task and press `<leader>nx`

4. **Check progress**: `:CSNotesTasks` to see all incomplete tasks

5. **View statistics**: `:CSNotesTaskStats` to see completion rate

## Tips

1. **Quick navigation**: Use `j`/`k` to move between tasks, `<leader>nx` to toggle
2. **Visual mode**: Toggle one task at a time (visual mode not supported)
3. **Save often**: Remember to `:w` to save your changes
4. **Task list**: Use `:CSNotesTasks` to jump to tasks across all notes

## Comparison with Manual Editing

### Manual Method:
1. Enter insert mode (`i`)
2. Navigate to the checkbox
3. Change `[ ]` to `[x]`
4. Exit insert mode (`Esc`)

### With Toggle Feature:
1. Press `<leader>nx`

**Result**: 75% fewer keystrokes! 🎉

## Files Modified

- `lua/csnotes/tasks.lua` - Added `toggle_task_completion()` and `toggle_task()`
- `lua/csnotes/init.lua` - Added `toggle_task()` API function
- `lua/csnotes/config.lua` - Added `toggle_task` to default mappings
- `plugin/csnotes.lua` - Added `:CSNotesTaskToggle` command and keybinding setup
- `tests/tasks_toggle_spec.lua` - Comprehensive test suite

## Future Enhancements

Potential improvements:
- Visual mode support (toggle multiple tasks at once)
- Toggle all tasks in current section
- Toggle all tasks in current file
- Repeat last toggle with `.` (dot command)
- Custom toggle states (e.g., `[-]` for in-progress)
