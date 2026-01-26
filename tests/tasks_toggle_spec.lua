local tasks = require("csnotes.tasks")
local config = require("csnotes.config")

describe("Task toggling", function()
  before_each(function()
    config.setup({})
  end)
  
  describe("toggle_task_completion", function()
    it("should mark incomplete task as complete", function()
      -- Create a buffer with a task
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# My Note",
        "",
        "- [ ] This is an incomplete task",
        "",
      })
      
      -- Toggle the task on line 3
      local success = tasks.toggle_task_completion(buf, 3)
      
      assert.is_true(success)
      
      -- Check the line was updated
      local lines = vim.api.nvim_buf_get_lines(buf, 2, 3, false)
      assert.equals("- [x] This is an incomplete task", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should mark complete task as incomplete", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# My Note",
        "",
        "- [x] This is a complete task",
        "",
      })
      
      local success = tasks.toggle_task_completion(buf, 3)
      
      assert.is_true(success)
      
      local lines = vim.api.nvim_buf_get_lines(buf, 2, 3, false)
      assert.equals("- [ ] This is a complete task", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should handle uppercase X in checkbox", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "- [X] Complete task with uppercase X",
      })
      
      local success = tasks.toggle_task_completion(buf, 1)
      
      assert.is_true(success)
      
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("- [ ] Complete task with uppercase X", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should handle indented tasks", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "  - [ ] Indented task",
        "    - [ ] More indented task",
      })
      
      -- Toggle first indented task
      local success = tasks.toggle_task_completion(buf, 1)
      assert.is_true(success)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("  - [x] Indented task", lines[1])
      
      -- Toggle more indented task
      success = tasks.toggle_task_completion(buf, 2)
      assert.is_true(success)
      lines = vim.api.nvim_buf_get_lines(buf, 1, 2, false)
      assert.equals("    - [x] More indented task", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should preserve task metadata (priority, due date, tags)", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "- [ ] !!! High priority task @due:2024-12-31 #important #work",
      })
      
      local success = tasks.toggle_task_completion(buf, 1)
      
      assert.is_true(success)
      
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("- [x] !!! High priority task @due:2024-12-31 #important #work", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should return false for non-task lines", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# This is a heading",
        "This is regular text",
        "- This is a bullet point, not a task",
        "",
      })
      
      -- Try to toggle heading
      local success = tasks.toggle_task_completion(buf, 1)
      assert.is_false(success)
      
      -- Try to toggle regular text
      success = tasks.toggle_task_completion(buf, 2)
      assert.is_false(success)
      
      -- Try to toggle bullet point
      success = tasks.toggle_task_completion(buf, 3)
      assert.is_false(success)
      
      -- Try to toggle empty line
      success = tasks.toggle_task_completion(buf, 4)
      assert.is_false(success)
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should handle multiple toggles", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "- [ ] Task to toggle multiple times",
      })
      
      -- Toggle to complete
      tasks.toggle_task_completion(buf, 1)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("- [x] Task to toggle multiple times", lines[1])
      
      -- Toggle back to incomplete
      tasks.toggle_task_completion(buf, 1)
      lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("- [ ] Task to toggle multiple times", lines[1])
      
      -- Toggle to complete again
      tasks.toggle_task_completion(buf, 1)
      lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      assert.equals("- [x] Task to toggle multiple times", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    
    it("should work with tasks in mixed content", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# Daily Note",
        "",
        "## Tasks",
        "- [ ] First task",
        "- [x] Second task (done)",
        "- [ ] Third task",
        "",
        "## Notes",
        "Some notes here",
      })
      
      -- Toggle first task
      tasks.toggle_task_completion(buf, 4)
      local lines = vim.api.nvim_buf_get_lines(buf, 3, 4, false)
      assert.equals("- [x] First task", lines[1])
      
      -- Toggle second task (complete -> incomplete)
      tasks.toggle_task_completion(buf, 5)
      lines = vim.api.nvim_buf_get_lines(buf, 4, 5, false)
      assert.equals("- [ ] Second task (done)", lines[1])
      
      -- Toggle third task
      tasks.toggle_task_completion(buf, 6)
      lines = vim.api.nvim_buf_get_lines(buf, 5, 6, false)
      assert.equals("- [x] Third task", lines[1])
      
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
end)
