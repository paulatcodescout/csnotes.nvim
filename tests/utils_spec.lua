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
  
  describe("get_week_start", function()
    it("should return Monday for a date in the middle of the week", function()
      -- Wednesday, January 22, 2026
      local timestamp = os.time({year = 2026, month = 1, day = 22, hour = 12})
      local monday = utils.get_week_start(timestamp)
      local date = os.date("*t", monday)
      
      -- Should be Monday, January 19, 2026
      assert.equals(2026, date.year)
      assert.equals(1, date.month)
      assert.equals(19, date.day)
      assert.equals(0, date.hour)
      assert.equals(0, date.min)
      assert.equals(0, date.sec)
    end)
    
    it("should return same date if already Monday", function()
      -- Monday, January 19, 2026
      local timestamp = os.time({year = 2026, month = 1, day = 19, hour = 12})
      local monday = utils.get_week_start(timestamp)
      local date = os.date("*t", monday)
      
      assert.equals(2026, date.year)
      assert.equals(1, date.month)
      assert.equals(19, date.day)
      assert.equals(0, date.hour)
    end)
    
    it("should handle Sunday correctly", function()
      -- Sunday, January 25, 2026
      local timestamp = os.time({year = 2026, month = 1, day = 25, hour = 12})
      local monday = utils.get_week_start(timestamp)
      local date = os.date("*t", monday)
      
      -- Should be Monday, January 19, 2026
      assert.equals(2026, date.year)
      assert.equals(1, date.month)
      assert.equals(19, date.day)
    end)
  end)
  
  describe("get_week_end", function()
    it("should return Sunday for a date in the week", function()
      -- Wednesday, January 22, 2026
      local timestamp = os.time({year = 2026, month = 1, day = 22, hour = 12})
      local sunday = utils.get_week_end(timestamp)
      local date = os.date("*t", sunday)
      
      -- Should be Sunday, January 25, 2026
      assert.equals(2026, date.year)
      assert.equals(1, date.month)
      assert.equals(25, date.day)
      assert.equals(23, date.hour)
      assert.equals(59, date.min)
    end)
  end)
  
  describe("format_week_range", function()
    it("should format week range correctly", function()
      -- Wednesday, January 22, 2026
      local timestamp = os.time({year = 2026, month = 1, day = 22, hour = 12})
      local range = utils.format_week_range(timestamp)
      
      -- Week runs from Monday Jan 19 to Sunday Jan 25
      assert.is_not_nil(range:match("January 19"))
      assert.is_not_nil(range:match("January 25"))
      assert.is_not_nil(range:match("2026"))
    end)
  end)
end)
