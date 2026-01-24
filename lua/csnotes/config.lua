local M = {}

--- Default configuration
M.defaults = {
  -- Directory where notes are stored
  notes_dir = "~/notes/daily",
  
  -- Directory for general notes
  general_notes_dir = "~/notes/general",
  
  -- Directory for archived notes
  archive_dir = "~/notes/archive",
  
  -- Date format for filenames (using strftime format)
  date_format = "%Y-%m-%d",
  
  -- Date format for headers
  header_date_format = "%A, %B %d, %Y",
  
  -- Template for new daily notes
  template = [[# {date}

## Tasks
- [ ] 

## Notes

## Tags
]],
  
  -- General notes filename
  general_notes_file = "general.md",
  
  -- Auto-archive notes older than this many days (0 to disable)
  auto_archive_days = 0,
  
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
    -- Backup on save
    on_save = false,
  },
  
  -- Frontmatter configuration
  frontmatter = {
    enabled = true,
    -- Fields to include in frontmatter
    fields = {
      "title",
      "created",
      "modified",
      "tags",
    },
    -- Auto-update modified date on save
    auto_update_modified = true,
  },
  
  -- Template variables
  template_vars = {
    -- Additional custom variables for templates
    -- {date}, {time}, {title}, {tags} are built-in
  },
  
  -- Statistics
  statistics = {
    enabled = true,
    -- Show word count, line count, etc.
    show_on_open = false,
  },
  
  -- Note linking
  linking = {
    enabled = true,
    -- Style: "wiki" ([[note]]) or "markdown" ([text](note.md))
    style = "wiki",
    -- Show backlinks
    show_backlinks = true,
  },
}

--- Current configuration
M.options = {}

--- Setup configuration
---@param opts table|nil User configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

--- Get a configuration option
---@param key string
---@return any
function M.get(key)
  local keys = vim.split(key, ".", { plain = true })
  local value = M.options
  
  for _, k in ipairs(keys) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[k]
  end
  
  return value
end

--- Set a configuration option
---@param key string
---@param value any
function M.set(key, value)
  local keys = vim.split(key, ".", { plain = true })
  local current = M.options
  
  for i = 1, #keys - 1 do
    local k = keys[i]
    if type(current[k]) ~= "table" then
      current[k] = {}
    end
    current = current[k]
  end
  
  current[keys[#keys]] = value
end

return M
