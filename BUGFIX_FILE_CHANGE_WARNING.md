# Fix: File Changed Warning on Save

## Problem

When saving a note file, users were getting a warning:
```
WARNING: The file has been changed since reading it!!!
Do you really want to write to it (y/n)?
```

## Root Cause

The issue was in the frontmatter auto-update feature:

1. **BufWritePre** autocmd was triggered before Neovim writes the buffer
2. `update_modified_time()` function would:
   - Read the file from disk
   - Update the frontmatter modified timestamp
   - **Write directly to the file on disk**
3. When Neovim then tried to write the buffer, it detected the file had changed on disk
4. This triggered the "file has been changed" warning

### Code Flow (Before Fix)

```
User presses :w
  ↓
BufWritePre event fires
  ↓
update_modified_time(file_path) called
  ↓
Read file from disk → Update frontmatter → Write to disk ❌
  ↓
Neovim detects file changed on disk
  ↓
WARNING: File has been changed!
```

## Solution

Changed `update_modified_time()` to update the **buffer content** instead of writing to the file directly:

### Code Flow (After Fix)

```
User presses :w
  ↓
BufWritePre event fires
  ↓
update_modified_time(bufnr) called
  ↓
Read buffer → Update frontmatter → Update buffer ✓
  ↓
Neovim writes buffer to disk (no conflict)
  ↓
Success! No warning.
```

## Changes Made

### 1. Updated `frontmatter.lua` (line 54)

**Before:**
```lua
function M.update_modified_time(path)
  -- Read from file
  local content, err = utils.read_file(path)
  
  -- Update frontmatter
  frontmatter.modified = utils.format_date("%Y-%m-%d %H:%M:%S", os.time())
  
  -- Write back to file (causes conflict!)
  utils.write_file(path, updated_content)
end
```

**After:**
```lua
function M.update_modified_time(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Read from buffer (not file)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Update frontmatter
  frontmatter.modified = utils.format_date("%Y-%m-%d %H:%M:%S", os.time())
  
  -- Update buffer content (not file)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
end
```

### 2. Updated `init.lua` (line 63)

**Before:**
```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local file_path = vim.fn.expand("%:p")
    get_frontmatter().update_modified_time(file_path)
  end,
})
```

**After:**
```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(args)
    local file_path = vim.fn.expand("%:p")
    local notes_dir = vim.fn.expand(config.get("notes_dir"))
    local general_dir = vim.fn.expand(config.get("general_notes_dir"))
    
    -- Only update files in the notes directories
    if file_path:find(notes_dir, 1, true) == 1 or 
       file_path:find(general_dir, 1, true) == 1 then
      get_frontmatter().update_modified_time(args.buf)
    end
  end,
})
```

## Additional Improvements

1. **Now updates PARA notes too**: Added check for `general_notes_dir` so frontmatter updates work in PARA category files (projects, areas, resources, archive)

2. **More efficient**: Reading from buffer is faster than reading from disk

3. **Safer**: No risk of race conditions between buffer and file

## Testing

To verify the fix works:

1. Create or open a note with frontmatter:
   ```markdown
   ---
   title: Test Note
   created: 2024-01-01
   modified: 2024-01-01 10:00:00
   ---
   
   # Test Note
   
   Content here.
   ```

2. Make any change to the content

3. Save the file (`:w`)

4. **Expected**: File saves without warning, `modified` timestamp is updated

5. **Before fix**: Would show "WARNING: The file has been changed since reading it!!!"

## Configuration

This fix applies when frontmatter auto-update is enabled (default):

```lua
require("csnotes").setup({
  frontmatter = {
    enabled = true,
    auto_update_modified = true,  -- This is the feature that was causing the warning
  },
})
```

If you don't want automatic modified timestamp updates, you can disable it:

```lua
require("csnotes").setup({
  frontmatter = {
    enabled = true,
    auto_update_modified = false,  -- Disable auto-update
  },
})
```

## Impact

- ✅ No more file change warnings
- ✅ Frontmatter modified timestamps still update automatically
- ✅ Works for daily notes and PARA notes
- ✅ More efficient (buffer operations vs disk I/O)
- ✅ Safer (no file system race conditions)

## Related Files

- `lua/csnotes/frontmatter.lua` - Updated `update_modified_time()` function
- `lua/csnotes/init.lua` - Updated BufWritePre autocmd
