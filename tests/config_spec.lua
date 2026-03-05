-- Test suite for config module

local config = require("csnotes.config")

describe("config", function()
  before_each(function()
    -- Reset config to defaults before each test
    config.setup()
  end)
  
  describe("setup", function()
    it("should use default config when no options provided", function()
      config.setup()
      assert.equals("~/notes/daily", config.get("notes_dir"))
      assert.equals("%Y-%m-%d", config.get("date_format"))
      assert.equals("weekly", config.get("note_type"))
      assert.equals("%Y-W%V", config.get("week_format"))
    end)
    
    it("should merge user options with defaults", function()
      config.setup({
        notes_dir = "~/custom/notes",
        date_format = "%Y%m%d",
      })
      
      assert.equals("~/custom/notes", config.get("notes_dir"))
      assert.equals("%Y%m%d", config.get("date_format"))
      -- Default values should still be present
      assert.equals("~/notes/general", config.get("general_notes_dir"))
    end)
    
    it("should handle nested options", function()
      config.setup({
        backup = {
          enabled = true,
          dir = "~/backups",
        },
      })
      
      assert.is_true(config.get("backup.enabled"))
      assert.equals("~/backups", config.get("backup.dir"))
    end)
  end)
  
  describe("get", function()
    it("should retrieve simple config values", function()
      assert.equals("~/notes/daily", config.get("notes_dir"))
    end)
    
    it("should retrieve nested config values", function()
      assert.equals("<leader>nd", config.get("mappings.open_daily"))
    end)
    
    it("should return nil for non-existent keys", function()
      assert.is_nil(config.get("non.existent.key"))
    end)
  end)
  
  describe("set", function()
    it("should set simple config values", function()
      config.set("notes_dir", "~/new/path")
      assert.equals("~/new/path", config.get("notes_dir"))
    end)
    
    it("should set nested config values", function()
      config.set("mappings.open_daily", "<leader>dn")
      assert.equals("<leader>dn", config.get("mappings.open_daily"))
    end)
    
    it("should create nested structure if it doesn't exist", function()
      config.set("new.nested.key", "value")
      assert.equals("value", config.get("new.nested.key"))
    end)
  end)
  
  describe("note_type configuration", function()
    it("should default to weekly notes", function()
      config.setup()
      assert.equals("weekly", config.get("note_type"))
    end)
    
    it("should allow switching to daily notes", function()
      config.setup({
        note_type = "daily",
      })
      assert.equals("daily", config.get("note_type"))
    end)
    
    it("should have week-specific configuration", function()
      config.setup()
      assert.equals("%Y-W%V", config.get("week_format"))
      assert.equals("Week %V, %Y", config.get("week_header_format"))
    end)
  end)
end)
