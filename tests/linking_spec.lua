local linking = require("csnotes.linking")
local utils = require("csnotes.utils")
local config = require("csnotes.config")

describe("Linking module", function()
  local test_dir
  
  before_each(function()
    -- Set up test directory
    test_dir = vim.fn.tempname()
    vim.fn.mkdir(test_dir, "p")
    
    config.setup({
      notes_dir = test_dir .. "/daily",
      general_notes_dir = test_dir .. "/general",
      linking = {
        enabled = true,
        style = "wiki",
        show_backlinks = true,
      },
    })
    
    vim.fn.mkdir(test_dir .. "/daily", "p")
    vim.fn.mkdir(test_dir .. "/general", "p")
  end)
  
  after_each(function()
    -- Clean up test directory
    vim.fn.delete(test_dir, "rf")
  end)
  
  describe("extract_links (utils)", function()
    it("should extract simple wiki links", function()
      local content = "This is a [[test-note]] link"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should extract wiki links with pipe syntax", function()
      local content = "This is a [[test-note|Alternative Text]] link"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should trim whitespace in wiki links with pipes", function()
      local content = "This is a [[test-note | Alternative Text ]] link"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should extract markdown links with .md extension", function()
      local content = "This is a [link text](test-note.md) link"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should extract markdown links without .md extension", function()
      local content = "This is a [link text](test-note) link"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should extract multiple links", function()
      local content = [[
        Here are some links:
        - [[first-note]]
        - [[second-note|Second Note]]
        - [Third](third-note.md)
        - [Fourth](fourth-note)
      ]]
      local links = utils.extract_links(content)
      
      assert.equals(4, #links)
      assert.is_true(vim.tbl_contains(links, "first-note"))
      assert.is_true(vim.tbl_contains(links, "second-note"))
      assert.is_true(vim.tbl_contains(links, "third-note"))
      assert.is_true(vim.tbl_contains(links, "fourth-note"))
    end)
    
    it("should not duplicate links", function()
      local content = "[[test-note]] and [[test-note]] again"
      local links = utils.extract_links(content)
      
      assert.equals(1, #links)
      assert.equals("test-note", links[1])
    end)
    
    it("should handle links with special characters", function()
      local content = "[[my-note-2023]] and [[note_with_underscore]]"
      local links = utils.extract_links(content)
      
      assert.equals(2, #links)
      assert.is_true(vim.tbl_contains(links, "my-note-2023"))
      assert.is_true(vim.tbl_contains(links, "note_with_underscore"))
    end)
  end)
  
  describe("get_backlinks", function()
    it("should find backlinks from simple wiki links", function()
      local target_note = test_dir .. "/daily/target.md"
      local source_note = test_dir .. "/daily/source.md"
      
      utils.write_file(target_note, "# Target Note\n\nContent")
      utils.write_file(source_note, "# Source Note\n\nThis links to [[target]]")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(1, #backlinks)
      assert.equals(source_note, backlinks[1].path)
      assert.is_true(backlinks[1].content:match("target"))
    end)
    
    it("should find backlinks from wiki links with pipe syntax", function()
      local target_note = test_dir .. "/daily/target.md"
      local source_note = test_dir .. "/daily/source.md"
      
      utils.write_file(target_note, "# Target Note\n\nContent")
      utils.write_file(source_note, "# Source Note\n\nThis links to [[target|Target Note]]")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(1, #backlinks)
      assert.equals(source_note, backlinks[1].path)
    end)
    
    it("should find backlinks from markdown links", function()
      local target_note = test_dir .. "/daily/target.md"
      local source_note = test_dir .. "/daily/source.md"
      
      utils.write_file(target_note, "# Target Note\n\nContent")
      utils.write_file(source_note, "# Source Note\n\nThis links to [Target](target.md)")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(1, #backlinks)
      assert.equals(source_note, backlinks[1].path)
    end)
    
    it("should find backlinks from markdown links without .md", function()
      local target_note = test_dir .. "/daily/target.md"
      local source_note = test_dir .. "/daily/source.md"
      
      utils.write_file(target_note, "# Target Note\n\nContent")
      utils.write_file(source_note, "# Source Note\n\nThis links to [Target](target)")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(1, #backlinks)
      assert.equals(source_note, backlinks[1].path)
    end)
    
    it("should find backlinks from multiple notes", function()
      local target_note = test_dir .. "/daily/target.md"
      local source1 = test_dir .. "/daily/source1.md"
      local source2 = test_dir .. "/general/source2.md"
      
      utils.write_file(target_note, "# Target Note\n\nContent")
      utils.write_file(source1, "# Source 1\n\nLinks to [[target]]")
      utils.write_file(source2, "# Source 2\n\nAlso links to [[target|Target]]")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(2, #backlinks)
    end)
    
    it("should not include the note itself as a backlink", function()
      local target_note = test_dir .. "/daily/target.md"
      
      utils.write_file(target_note, "# Target Note\n\nSelf-reference [[target]]")
      
      local backlinks = linking.get_backlinks(target_note)
      
      assert.equals(0, #backlinks)
    end)
  end)
  
  describe("follow_link edge cases", function()
    -- Note: These tests verify the pattern matching logic
    -- Full integration tests require setting up buffers and cursor positions
    
    it("should extract note name from wiki link with pipe", function()
      local line = "This is [[my-note|My Note Title]] in text"
      local note_name = line:match("%[%[([^|]+)")
      
      assert.equals("my-note", note_name)
    end)
    
    it("should extract note name from markdown link", function()
      local line = "This is [text](my-note.md) in text"
      local note_file = line:match("%]%(([^%)]+)%)")
      local note_name = note_file:match("^(.+)%.md$") or note_file
      
      assert.equals("my-note", note_name)
    end)
    
    it("should handle note names with special characters", function()
      local line = "Link to [[my-note-2023|Note from 2023]]"
      local note_name = line:match("%[%[([^|]+)")
      
      assert.equals("my-note-2023", note_name)
    end)
  end)
end)
