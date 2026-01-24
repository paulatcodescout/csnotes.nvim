local utils = require("csnotes.utils")
local config = require("csnotes.config")

local M = {}

--- Generate frontmatter metadata for a new note
---@param path string Note file path
---@param opts table|nil Options
---@return table metadata
function M.generate_metadata(path, opts)
  opts = opts or {}
  local metadata = {}
  
  if not config.get("frontmatter.enabled") then
    return metadata
  end
  
  local fields = config.get("frontmatter.fields") or {}
  local filename = vim.fn.fnamemodify(path, ":t:r")
  local now = os.time()
  
  for _, field in ipairs(fields) do
    if field == "title" then
      metadata.title = opts.title or filename
    elseif field == "created" then
      metadata.created = utils.format_date("%Y-%m-%d %H:%M:%S", now)
    elseif field == "modified" then
      metadata.modified = utils.format_date("%Y-%m-%d %H:%M:%S", now)
    elseif field == "tags" then
      metadata.tags = opts.tags or {}
    elseif field == "date" then
      metadata.date = utils.format_date("%Y-%m-%d", now)
    end
  end
  
  return metadata
end

--- Add frontmatter to template content
---@param template string Template content
---@param metadata table Frontmatter metadata
---@return string Content with frontmatter
function M.add_frontmatter_to_template(template, metadata)
  if not config.get("frontmatter.enabled") or vim.tbl_isempty(metadata) then
    return template
  end
  
  return utils.generate_frontmatter(metadata) .. template
end

--- Update modified timestamp in buffer
---@param bufnr number|nil Buffer number (defaults to current buffer)
---@return boolean success
function M.update_modified_time(bufnr)
  if not config.get("frontmatter.enabled") or not config.get("frontmatter.auto_update_modified") then
    return false
  end
  
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Get buffer content instead of reading from file
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  local frontmatter, body = utils.parse_frontmatter(content)
  if not frontmatter then
    return false
  end
  
  -- Update modified time
  frontmatter.modified = utils.format_date("%Y-%m-%d %H:%M:%S", os.time())
  
  -- Update buffer content instead of writing to file
  local updated_content = utils.generate_frontmatter(frontmatter) .. body
  local updated_lines = vim.split(updated_content, "\n", { plain = true })
  
  -- Set buffer lines
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
  
  return true
end

--- Extract metadata from existing note
---@param path string File path
---@return table|nil metadata
function M.get_metadata(path)
  local content, err = utils.read_file(path)
  if not content then
    return nil
  end
  
  local frontmatter, _ = utils.parse_frontmatter(content)
  return frontmatter
end

--- Update metadata in note
---@param path string File path
---@param updates table Metadata updates
---@return boolean success
function M.update_metadata(path, updates)
  local content, err = utils.read_file(path)
  if not content then
    return false
  end
  
  local updated_content = utils.update_frontmatter(content, updates)
  local ok, write_err = utils.write_file(path, updated_content)
  
  return ok == true
end

--- Add tags to note metadata
---@param path string File path
---@param tags table|string Tags to add
---@return boolean success
function M.add_tags(path, tags)
  if type(tags) == "string" then
    tags = {tags}
  end
  
  local metadata = M.get_metadata(path)
  if not metadata then
    metadata = {tags = {}}
  end
  
  if not metadata.tags then
    metadata.tags = {}
  elseif type(metadata.tags) == "string" then
    metadata.tags = {metadata.tags}
  end
  
  for _, tag in ipairs(tags) do
    if not vim.tbl_contains(metadata.tags, tag) then
      table.insert(metadata.tags, tag)
    end
  end
  
  return M.update_metadata(path, {tags = metadata.tags})
end

--- Remove tags from note metadata
---@param path string File path
---@param tags table|string Tags to remove
---@return boolean success
function M.remove_tags(path, tags)
  if type(tags) == "string" then
    tags = {tags}
  end
  
  local metadata = M.get_metadata(path)
  if not metadata or not metadata.tags then
    return false
  end
  
  if type(metadata.tags) == "string" then
    metadata.tags = {metadata.tags}
  end
  
  local new_tags = {}
  for _, tag in ipairs(metadata.tags) do
    if not vim.tbl_contains(tags, tag) then
      table.insert(new_tags, tag)
    end
  end
  
  return M.update_metadata(path, {tags = new_tags})
end

return M
