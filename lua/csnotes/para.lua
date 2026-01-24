local utils = require("csnotes.utils")
local config = require("csnotes.config")

local M = {}

--- PARA categories
M.PARA_CATEGORIES = {
  "Projects",
  "Areas",
  "Resources",
  "Archive",
}

--- Get the path for a PARA category file
---@param category string Category name
---@return string
local function get_para_file_path(category)
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  return general_dir .. "/" .. category:lower() .. ".md"
end

--- Get the dashboard (general.md) path
---@return string
local function get_dashboard_path()
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  return general_dir .. "/" .. config.get("general_notes_file")
end

--- Initialize PARA structure
---@return boolean success
---@return string|nil error
function M.initialize_para()
  local general_dir = utils.expand_path(config.get("general_notes_dir"))
  local ok, err = utils.mkdir_p(general_dir)
  if not ok then
    return false, "Failed to create general notes directory: " .. (err or "unknown error")
  end
  
  -- Create PARA files if they don't exist
  for _, category in ipairs(M.PARA_CATEGORIES) do
    local file_path = get_para_file_path(category)
    if not utils.file_exists(file_path) then
      local template = M.get_category_template(category)
      ok, err = utils.write_file(file_path, template)
      if not ok then
        return false, string.format("Failed to create %s file: %s", category, err or "unknown error")
      end
    end
  end
  
  -- Create or update dashboard
  local dashboard_path = get_dashboard_path()
  local dashboard_content = M.generate_dashboard()
  ok, err = utils.write_file(dashboard_path, dashboard_content)
  if not ok then
    return false, "Failed to create dashboard: " .. (err or "unknown error")
  end
  
  return true, nil
end

--- Get template for a PARA category
---@param category string
---@return string
function M.get_category_template(category)
  local templates = {
    Projects = [[# Projects

> Projects are short-term efforts with specific goals and deadlines.

## Active Projects

### Project Name
- **Goal**: 
- **Deadline**: 
- **Status**: 
- **Next Action**: 

---

## Completed Projects

]],
    Areas = [[# Areas of Responsibility

> Areas are ongoing responsibilities with standards to maintain.

## Personal Development
- 

## Health & Fitness
- 

## Relationships
- 

## Finance
- 

## Career
- 

---

]],
    Resources = [[# Resources

> Resources are topics of ongoing interest and reference materials.

## Learning Resources
- 

## Technical Documentation
- 

## Guides & Tutorials
- 

## Reference Materials
- 

---

]],
    Archive = [[# Archive

> Completed projects and inactive items.

## Archived Projects

---

## Archived Areas

---

## Archived Resources

---

]],
  }
  
  return templates[category] or string.format("# %s\n\n", category)
end

--- Generate dashboard content
---@return string
function M.generate_dashboard()
  local dashboard = [[# General Notes Dashboard

> This is your central hub for the PARA (Projects, Areas, Resources, Archive) method.

## Quick Links

- [[projects|Projects]] - Short-term efforts with goals and deadlines
- [[areas|Areas of Responsibility]] - Ongoing responsibilities
- [[resources|Resources]] - Reference materials and learning
- [[archive|Archive]] - Completed and inactive items

## PARA Method Overview

The PARA method helps organize information into four categories:

1. **Projects**: Things you're actively working on with a defined end goal
2. **Areas**: Ongoing responsibilities you need to maintain
3. **Resources**: Topics of interest and reference materials
4. **Archive**: Inactive items and completed projects

## Recent Activity

]]
  
  -- Add links to recent notes in each category
  for _, category in ipairs(M.PARA_CATEGORIES) do
    local file_path = get_para_file_path(category)
    if utils.file_exists(file_path) then
      dashboard = dashboard .. string.format("- Last updated: [[%s|%s]]\n", category:lower(), category)
    end
  end
  
  dashboard = dashboard .. [[

## Getting Started

To add a new item:
1. Click on the appropriate category link above
2. Add your item following the template structure
3. Return to this dashboard for easy navigation

---

*Last updated: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. "*\n"
  
  return dashboard
end

--- Update dashboard with current status
---@return boolean success
---@return string|nil error
function M.update_dashboard()
  local dashboard_content = M.generate_dashboard()
  local dashboard_path = get_dashboard_path()
  return utils.write_file(dashboard_path, dashboard_content)
end

--- Open a PARA category
---@param category string Category name (projects, areas, resources, archive)
---@param opts table|nil Options (split: "vertical"|"horizontal"|nil)
function M.open_category(category, opts)
  opts = opts or {}
  
  -- Normalize category name
  local category_map = {
    projects = "Projects",
    areas = "Areas",
    resources = "Resources",
    archive = "Archive",
  }
  
  local normalized_category = category_map[category:lower()]
  if not normalized_category then
    utils.error("Invalid category: " .. category)
    return
  end
  
  local file_path = get_para_file_path(normalized_category)
  
  -- Ensure PARA structure exists
  if not utils.file_exists(file_path) then
    local ok, err = M.initialize_para()
    if not ok then
      utils.error(err)
      return
    end
  end
  
  -- Open the file
  local cmd = "edit"
  if opts.split == "vertical" then
    cmd = "vsplit"
  elseif opts.split == "horizontal" then
    cmd = "split"
  end
  
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(file_path))
end

--- Get statistics about PARA notes
---@return table Statistics
function M.get_para_stats()
  local stats = {
    total_categories = 0,
    categories = {},
  }
  
  for _, category in ipairs(M.PARA_CATEGORIES) do
    local file_path = get_para_file_path(category)
    if utils.file_exists(file_path) then
      stats.total_categories = stats.total_categories + 1
      local content, err = utils.read_file(file_path)
      if content then
        stats.categories[category] = {
          word_count = utils.count_words(content),
          line_count = utils.count_lines(content),
          last_modified = utils.get_mtime(file_path),
        }
      end
    end
  end
  
  return stats
end

--- Show PARA category picker
function M.show_category_picker()
  local items = {}
  
  for _, category in ipairs(M.PARA_CATEGORIES) do
    local file_path = get_para_file_path(category)
    local status = utils.file_exists(file_path) and "✓" or "✗"
    table.insert(items, string.format("%s %s", status, category))
  end
  
  vim.ui.select(items, {
    prompt = "Select PARA category:",
  }, function(choice)
    if choice then
      local category = choice:match("^[✓✗] (.+)$")
      if category then
        M.open_category(category)
      end
    end
  end)
end

return M
