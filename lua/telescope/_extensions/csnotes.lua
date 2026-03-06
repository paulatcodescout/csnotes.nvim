local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

local daily = require("csnotes.daily")
local tags = require("csnotes.tags")
local archive = require("csnotes.archive")
local config = require("csnotes.config")
local utils = require("csnotes.utils")

local M = {}

--- Create a telescope picker for daily notes
local function daily_notes(opts)
  opts = opts or {}
  local notes = daily.get_all_daily_notes()
  
  pickers.new(opts, {
    prompt_title = "Daily Notes",
    finder = finders.new_table({
      results = notes,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.date or entry.filename,
          ordinal = entry.date or entry.filename,
          path = entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
      end)
      return true
    end,
  }):find()
end

--- Create a telescope picker for searching notes
local function search_notes(opts)
  opts = opts or {}
  
  -- Prompt for search query
  vim.ui.input({ prompt = "Search notes: " }, function(query)
    if not query or query == "" then
      return
    end
    
    local results = daily.search_notes(query)
    
    pickers.new(opts, {
      prompt_title = "Search Results",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          local display_text = string.format("%s:%d: %s", 
            entry.filename, 
            entry.line, 
            entry.content:gsub("^%s+", "")
          )
          
          return {
            value = entry,
            display = display_text,
            ordinal = display_text,
            path = entry.path,
            lnum = entry.line,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
          vim.api.nvim_win_set_cursor(0, {selection.lnum, 0})
        end)
        return true
      end,
    }):find()
  end)
end

--- Create a telescope picker for tags
local function tags_picker(opts)
  opts = opts or {}
  local tag_list = tags.list_tags()
  
  pickers.new(opts, {
    prompt_title = "Tags",
    finder = finders.new_table({
      results = tag_list,
      entry_maker = function(entry)
        local display_text = string.format("#%s (%d)", entry.tag, entry.count)
        return {
          value = entry,
          display = display_text,
          ordinal = entry.tag,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        -- Show notes for selected tag
        notes_by_tag({ tag = selection.value.tag })
      end)
      return true
    end,
  }):find()
end

--- Create a telescope picker for notes by tag
local function notes_by_tag(opts)
  opts = opts or {}
  local tag = opts.tag
  
  if not tag then
    vim.ui.input({ prompt = "Enter tag: " }, function(input)
      if input and input ~= "" then
        notes_by_tag({ tag = input })
      end
    end)
    return
  end
  
  local notes = tags.get_notes_by_tag(tag)
  
  pickers.new(opts, {
    prompt_title = string.format("Notes tagged #%s", tag),
    finder = finders.new_table({
      results = notes,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.date or entry.filename,
          ordinal = entry.date or entry.filename,
          path = entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
      end)
      return true
    end,
  }):find()
end

--- Create a telescope picker for archived notes
local function archived_notes(opts)
  opts = opts or {}
  local notes = archive.get_archived_notes()
  
  pickers.new(opts, {
    prompt_title = "Archived Notes",
    finder = finders.new_table({
      results = notes,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.filename,
          ordinal = entry.filename,
          path = entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
      end)
      
      -- Add restore action
      map("i", "<C-r>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local ok, err = archive.restore_note(selection.path)
        if ok then
          vim.notify("CSNotes: Note restored: " .. selection.value.filename, vim.log.levels.INFO)
        else
          vim.notify("CSNotes: Failed to restore: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
      
      map("n", "r", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local ok, err = archive.restore_note(selection.path)
        if ok then
          vim.notify("CSNotes: Note restored: " .. selection.value.filename, vim.log.levels.INFO)
        else
          vim.notify("CSNotes: Failed to restore: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
      
      return true
    end,
  }):find()
end

--- Get all notes from daily and general directories (including subdirectories)
---@return table Array of {path: string, filename: string, relative_path: string, source: string}
local function get_all_notes_recursive()
  local all_notes = {}
  
  -- Get daily notes
  local daily_dir = utils.expand_path(config.get("notes_dir"))
  if utils.dir_exists(daily_dir) then
    local daily_files = utils.get_files_recursive(daily_dir, "%.md$")
    for _, file in ipairs(daily_files) do
      table.insert(all_notes, {
        path = file.path,
        filename = file.filename,
        relative_path = file.relative_path,
        source = "daily",
      })
    end
  end
  
  -- Get general notes
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  if utils.dir_exists(general_dir) then
    local general_files = utils.get_files_recursive(general_dir, "%.md$")
    for _, file in ipairs(general_files) do
      table.insert(all_notes, {
        path = file.path,
        filename = file.filename,
        relative_path = file.relative_path,
        source = "general",
      })
    end
  end
  
  return all_notes
end

--- Create a telescope picker for inserting links
local function insert_link(opts)
  opts = opts or {}
  local all_notes = get_all_notes_recursive()
  
  if #all_notes == 0 then
    vim.notify("CSNotes: No notes found", vim.log.levels.WARN)
    return
  end
  
  local style = config.get("linking.style") or "wiki"
  
  pickers.new(opts, {
    prompt_title = "Insert Link to Note",
    finder = finders.new_table({
      results = all_notes,
      entry_maker = function(entry)
        -- Display format: "relative/path/to/note.md (daily)"
        local display_text = string.format("%s (%s)", entry.relative_path, entry.source)
        
        return {
          value = entry,
          display = display_text,
          ordinal = entry.relative_path,
          path = entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        
        -- Get note name without extension
        local note_name = selection.value.relative_path:match("^(.+)%.md$") or selection.value.relative_path
        
        -- Create link text based on style
        local link_text
        if style == "wiki" then
          link_text = string.format("[[%s]]", note_name)
        else
          link_text = string.format("[%s](%s)", note_name, note_name .. ".md")
        end
        
        -- Insert at cursor position
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local new_line = line:sub(1, col) .. link_text .. line:sub(col + 1)
        vim.api.nvim_set_current_line(new_line)
        
        -- Move cursor after the link
        vim.api.nvim_win_set_cursor(0, {row, col + #link_text})
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension({
  setup = function(ext_config, user_config)
    -- Extension setup if needed
  end,
  exports = {
    csnotes = daily_notes,
    daily = daily_notes,
    search = search_notes,
    tags = tags_picker,
    by_tag = notes_by_tag,
    archive = archived_notes,
    insert_link = insert_link,
  },
})
