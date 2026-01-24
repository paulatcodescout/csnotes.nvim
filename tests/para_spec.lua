local para = require("csnotes.para")
local config = require("csnotes.config")
local utils = require("csnotes.utils")

describe("PARA module", function()
  local test_dir
  
  before_each(function()
    -- Set up test directory
    test_dir = vim.fn.tempname()
    vim.fn.mkdir(test_dir, "p")
    
    config.setup({
      general_notes_dir = test_dir,
      general_notes_file = "general.md",
    })
  end)
  
  after_each(function()
    -- Clean up test directory
    vim.fn.delete(test_dir, "rf")
  end)
  
  describe("initialize_para", function()
    it("should create all PARA category files", function()
      local ok, err = para.initialize_para()
      
      assert.is_true(ok)
      assert.is_nil(err)
      
      -- Check that all category files exist
      for _, category in ipairs(para.PARA_CATEGORIES) do
        local file_path = test_dir .. "/" .. category:lower() .. ".md"
        assert.is_true(utils.file_exists(file_path))
      end
    end)
    
    it("should create the dashboard file", function()
      local ok, err = para.initialize_para()
      
      assert.is_true(ok)
      assert.is_nil(err)
      
      local dashboard_path = test_dir .. "/general.md"
      assert.is_true(utils.file_exists(dashboard_path))
    end)
    
    it("should not overwrite existing files", function()
      -- Create a custom projects file
      local projects_path = test_dir .. "/projects.md"
      utils.write_file(projects_path, "# My Custom Projects\n\nCustom content")
      
      local ok, err = para.initialize_para()
      assert.is_true(ok)
      
      -- Verify the custom content is preserved
      local content, _ = utils.read_file(projects_path)
      assert.is_not_nil(content:match("Custom content"))
    end)
  end)
  
  describe("get_category_template", function()
    it("should return a template for each PARA category", function()
      for _, category in ipairs(para.PARA_CATEGORIES) do
        local template = para.get_category_template(category)
        
        assert.is_string(template)
        assert.is_not_nil(template:match("# " .. category))
      end
    end)
    
    it("should return a default template for unknown categories", function()
      local template = para.get_category_template("Unknown")
      assert.is_string(template)
      assert.is_not_nil(template:match("# Unknown"))
    end)
  end)
  
  describe("generate_dashboard", function()
    it("should generate dashboard with PARA links", function()
      local dashboard = para.generate_dashboard()
      
      assert.is_string(dashboard)
      assert.is_not_nil(dashboard:match("# General Notes Dashboard"))
      assert.is_not_nil(dashboard:match("%[%[projects"))
      assert.is_not_nil(dashboard:match("%[%[areas"))
      assert.is_not_nil(dashboard:match("%[%[resources"))
      assert.is_not_nil(dashboard:match("%[%[archive"))
    end)
    
    it("should include PARA method overview", function()
      local dashboard = para.generate_dashboard()
      
      assert.is_not_nil(dashboard:match("PARA Method Overview"))
      assert.is_not_nil(dashboard:match("Projects"))
      assert.is_not_nil(dashboard:match("Areas"))
      assert.is_not_nil(dashboard:match("Resources"))
      assert.is_not_nil(dashboard:match("Archive"))
    end)
  end)
  
  describe("get_para_stats", function()
    it("should return statistics for existing PARA files", function()
      para.initialize_para()
      
      local stats = para.get_para_stats()
      
      assert.is_table(stats)
      assert.is_number(stats.total_categories)
      assert.equals(4, stats.total_categories)
      assert.is_table(stats.categories)
    end)
    
    it("should include word count and line count", function()
      para.initialize_para()
      
      local stats = para.get_para_stats()
      
      for _, category in ipairs(para.PARA_CATEGORIES) do
        if stats.categories[category] then
          assert.is_number(stats.categories[category].word_count)
          assert.is_number(stats.categories[category].line_count)
        end
      end
    end)
  end)
  
  describe("update_dashboard", function()
    it("should update the dashboard file", function()
      para.initialize_para()
      
      -- Get original dashboard
      local dashboard_path = test_dir .. "/general.md"
      local original_content, _ = utils.read_file(dashboard_path)
      
      -- Wait a moment to ensure timestamp changes
      vim.loop.sleep(1000)
      
      -- Update dashboard
      local ok = para.update_dashboard()
      assert.is_true(ok)
      
      -- Verify content was updated
      local new_content, _ = utils.read_file(dashboard_path)
      assert.is_string(new_content)
      assert.is_not_nil(new_content:match("Last updated:"))
    end)
  end)
end)
