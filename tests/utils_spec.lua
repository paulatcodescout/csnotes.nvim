-- Test suite for utils module
-- Run with: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

local utils = require("csnotes.utils")

describe("utils", function()
  describe("extract_tags", function()
    it("should extract tags from content", function()
      local content = "This is a note with #tag1 and #tag2"
      local tags = utils.extract_tags(content)
      assert.are.same({"tag1", "tag2"}, tags)
    end)
    
    it("should handle multiple instances of same tag", function()
      local content = "This has #tag1 and also #tag1 again"
      local tags = utils.extract_tags(content)
      assert.are.same({"tag1"}, tags)
    end)
    
    it("should handle tags with underscores and hyphens", function()
      local content = "Tags: #project_alpha #work-notes #test123"
      local tags = utils.extract_tags(content)
      assert.are.same({"project_alpha", "work-notes", "test123"}, tags)
    end)
    
    it("should return empty table for content with no tags", function()
      local content = "This is a note without any tags"
      local tags = utils.extract_tags(content)
      assert.are.same({}, tags)
    end)
  end)
  
  describe("format_date", function()
    it("should format date correctly", function()
      local timestamp = os.time({year = 2026, month = 1, day = 23, hour = 12})
      local formatted = utils.format_date("%Y-%m-%d", timestamp)
      assert.equals("2026-01-23", formatted)
    end)
    
    it("should handle different formats", function()
      local timestamp = os.time({year = 2026, month = 1, day = 23, hour = 12})
      local formatted = utils.format_date("%d/%m/%Y", timestamp)
      assert.equals("23/01/2026", formatted)
    end)
  end)
  
  describe("parse_date_from_filename", function()
    it("should parse date from filename", function()
      local filename = "2026-01-23.md"
      local timestamp = utils.parse_date_from_filename(filename, "%Y-%m-%d")
      assert.is_not_nil(timestamp)
      
      local date = os.date("*t", timestamp)
      assert.equals(2026, date.year)
      assert.equals(1, date.month)
      assert.equals(23, date.day)
    end)
    
    it("should handle filenames without extension", function()
      local filename = "2026-01-23"
      local timestamp = utils.parse_date_from_filename(filename, "%Y-%m-%d")
      assert.is_not_nil(timestamp)
    end)
  end)
  
  describe("expand_path", function()
    it("should expand tilde", function()
      local path = "~/test"
      local expanded = utils.expand_path(path)
      assert.is_not_nil(expanded:match("^/"))
      assert.is_nil(expanded:match("^~"))
    end)
  end)
end)
