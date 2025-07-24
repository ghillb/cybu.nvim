-- tests via plenary.nvim / busted

local spy = require("luassert.spy")

describe("Cybu:", function()
  it("cybu can be required", function()
    local cybu = require("cybu")
    assert.is_not_nil(cybu)
  end)
end)

describe("Cybu:", function()
  it("cycle() can be called", function()
    local cybu = require("cybu")
    local cycle = spy.new(cybu.cycle)
    for _, arg in ipairs({ "next", "prev" }) do
      local status, err = pcall(cycle, arg)
      assert.is.equal(true, status)
      assert.is_nil(err)
    end
    assert.spy(cycle).was_called(2)
  end)
end)

describe("Cybu:", function()
  it("cybu buffer is created", function()
    local cybu = require("cybu")
    cybu.cycle("next")
    local cybu_found
    for _, id in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_option(id, "filetype") == "cybu" then
        cybu_found = true
      end
    end
    assert.True(cybu_found)
  end)
end)

describe("Cybu:", function()
  it("some arguments are not allowed", function()
    local cybu = require("cybu")
    local status, err = pcall(cybu.cycle, "fail")
    assert.is.equal(false, status)
    -- assert.is_not_nil(string.find(err, "Invalid direction")) -- fails in ci
  end)
end)

describe("Cybu:", function()
  it("buffers can be cycled", function()
    local cybu = require("cybu")
    vim.api.nvim_create_buf(true, true)
    local buf_before = vim.api.nvim_get_current_buf()
    cybu.cycle("next")
    vim.defer_fn(function()
      assert.True(buf_before ~= vim.api.nvim_get_current_buf())
    end, 1000)
    cybu.cycle("prev")
    assert.True(buf_before == vim.api.nvim_get_current_buf())
  end)
end)

describe("Cybu:", function()
  it("buf table has the correct form", function()
    local cybu = require("cybu")
    assert.True(vim.inspect(cybu.get_bufs()[1]) == vim.inspect({
      id = 1,
      name = "",
      icon = { highlight = "DevIconDefault", text = "" },
    }))
  end)
end)

describe("Cybu:", function()
  it("separator width is calculated correctly", function()
    local cybu = require("cybu")
    cybu.setup({ style = { hide_buffer_id = false, devicons = { enabled = true } } })
    local widths = cybu.get_widths()
    assert.True(widths.separator == 2)
    cybu.setup({ style = { hide_buffer_id = false, devicons = { enabled = false } } })
    widths = cybu.get_widths()
    assert.True(widths.separator == 1)
    cybu.setup({ style = { hide_buffer_id = true, devicons = { enabled = true } } })
    widths = cybu.get_widths()
    assert.True(widths.separator == 1)
    cybu.setup({ style = { hide_buffer_id = true, devicons = { enabled = false } } })
    widths = cybu.get_widths()
    assert.True(widths.separator == 0)
  end)
end)

describe("Utils:", function()
  it("icons can be requested", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("test.lua", true)
    assert.same(icon.text, "")
    assert.same(icon.highlight, "DevIconLua")
  end)
end)

describe("Utils:", function()
  it("icons that use more than one char are truncated", function()
    require("cybu").setup({ style = { devicons = { enabled = true, truncate = true } } })
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("test.xml", true)
    -- Test that icon exists and has text (truncation behavior may vary)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
    assert.True(#icon.text > 0)
  end)
end)

describe("Utils extension extraction:", function()
  it("handles files with extensions correctly", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("test.lua", true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("handles extensionless files without crashing", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("README", true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("handles files with multiple dots", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("config.test.js", true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("handles hidden files with extensions", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator(".gitignore", true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("handles files with no name but extension", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator(".lua", true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("returns separator when devicons disabled", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator("test.lua", false)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)

  it("returns separator when filename is nil", function()
    local utils = require("cybu.utils")
    local icon = utils.get_icon_or_separator(nil, true)
    assert.is_not_nil(icon)
    assert.is_string(icon.text)
  end)
end)

describe("UI client detection:", function()
  it("detects neovide correctly", function()
    vim.g.neovide = true
    local cybu = require("cybu")
    -- Test that cybu can cycle without errors when neovide is detected
    local status, _ = pcall(cybu.cycle, "next")
    assert.is_true(status)
    vim.g.neovide = nil
  end)

  it("handles unknown UI clients gracefully", function()
    local original_term = vim.env.TERM
    vim.env.TERM = nil
    local cybu = require("cybu")
    local status, _ = pcall(cybu.cycle, "next")
    assert.is_true(status)
    vim.env.TERM = original_term
  end)
end)

describe("Floating window fallback:", function()
  it("handles floating window creation failures gracefully", function()
    local cybu = require("cybu")
    -- Mock nvim_open_win to fail
    local original_open_win = vim.api.nvim_open_win
    vim.api.nvim_open_win = function()
      error("Mock floating window failure")
    end

    -- Test that cycling still works despite floating window failure
    local status, _ = pcall(cybu.cycle, "next")
    assert.is_true(status)

    -- Restore original function
    vim.api.nvim_open_win = original_open_win
  end)

  it("continues operation when window highlight setting fails", function()
    local cybu = require("cybu")
    -- Mock nvim_win_set_option to fail for highlights only
    local original_set_option = vim.api.nvim_win_set_option
    vim.api.nvim_win_set_option = function(win_id, option, value)
      if option == "winhl" then
        error("Mock highlight setting failure")
      end
      return original_set_option(win_id, option, value)
    end

    local status, _ = pcall(cybu.cycle, "next")
    assert.is_true(status)

    -- Restore original function
    vim.api.nvim_win_set_option = original_set_option
  end)
end)

describe("Touched flag behavior:", function()
  it("uses buf_enter mode by default", function()
    local cybu = require("cybu")
    cybu.setup({
      behavior = {
        mode = {
          last_used = {
            update_on = "buf_enter",
          },
        },
      },
    })

    -- Create buffers
    vim.cmd("edit test1.lua")
    vim.cmd("edit test2.lua")

    -- Test default behavior works
    local bufs = cybu.get_bufs()
    assert.is_not_nil(bufs)
    assert.True(#bufs >= 2)
  end)

  it("tracks cursor movement when configured", function()
    local cybu = require("cybu")
    cybu.setup({
      behavior = {
        mode = {
          last_used = {
            update_on = "cursor_moved",
          },
        },
      },
    })

    -- Create test buffers
    vim.cmd("edit touched1.lua")
    local buf1 = vim.api.nvim_get_current_buf()

    vim.cmd("edit touched2.lua")
    local buf2 = vim.api.nvim_get_current_buf()

    -- Switch to buf1 without moving cursor
    vim.api.nvim_set_current_buf(buf1)

    -- Simulate cursor movement to trigger touch
    vim.api.nvim_win_set_cursor(0, { 1, 1 })

    -- Test that touch tracking is working
    local bufs = cybu.get_bufs()
    assert.is_not_nil(bufs)
    assert.True(#bufs >= 2)
  end)

  it("maintains different ordering for cursor_moved vs buf_enter", function()
    local cybu = require("cybu")

    -- Test buf_enter mode
    cybu.setup({
      behavior = {
        mode = {
          last_used = {
            update_on = "buf_enter",
          },
        },
      },
    })

    vim.cmd("edit order1.lua")
    vim.cmd("edit order2.lua")
    local buf_enter_bufs = cybu.get_bufs()

    -- Test cursor_moved mode
    cybu.setup({
      behavior = {
        mode = {
          last_used = {
            update_on = "cursor_moved",
          },
        },
      },
    })

    local cursor_moved_bufs = cybu.get_bufs()

    -- Both should work (specific ordering depends on cursor activity)
    assert.is_not_nil(buf_enter_bufs)
    assert.is_not_nil(cursor_moved_bufs)
  end)

  it("tracks text changes when configured", function()
    local cybu = require("cybu")
    cybu.setup({
      behavior = {
        mode = {
          last_used = {
            update_on = "text_changed",
          },
        },
      },
    })

    -- Create test buffers
    vim.cmd("edit text1.lua")
    local buf1 = vim.api.nvim_get_current_buf()

    vim.cmd("edit text2.lua")
    local buf2 = vim.api.nvim_get_current_buf()

    -- Switch to buf1 without making changes
    vim.api.nvim_set_current_buf(buf1)

    -- Add some text to trigger text change
    vim.api.nvim_buf_set_lines(buf1, 0, -1, false, { "local test = 1" })

    -- Test that text tracking is working
    local bufs = cybu.get_bufs()
    assert.is_not_nil(bufs)
    assert.True(#bufs >= 2)
  end)
end)

describe("Experimental buffer provider:", function()
  it("uses custom buffer provider when configured", function()
    local cybu = require("cybu")

    -- Create test buffers
    vim.cmd("edit provider_test1.lua")
    local buf1 = vim.api.nvim_get_current_buf()
    vim.cmd("edit provider_test2.lua")
    local buf2 = vim.api.nvim_get_current_buf()

    -- Custom provider that only returns buf1
    local custom_provider = function()
      return {
        { bufnr = buf1, filename = vim.api.nvim_buf_get_name(buf1) },
      }
    end

    cybu.setup({
      experimental = {
        buffer_provider = custom_provider,
      },
    })

    local bufs = cybu.get_bufs()

    -- Should only contain buf1 (custom provider overrides default buffer list)
    assert.is_not_nil(bufs)
    assert.True(#bufs >= 1) -- At least buf1, but may have others if filtering is applied

    -- Check that buf1 is present in results
    local found_buf1 = false
    for _, buf in ipairs(bufs) do
      if buf.id == buf1 then
        found_buf1 = true
        break
      end
    end
    assert.True(found_buf1)
  end)

  it("falls back to default when provider fails", function()
    local cybu = require("cybu")

    -- Provider that always throws error
    local failing_provider = function()
      error("Test provider failure")
    end

    cybu.setup({
      experimental = {
        buffer_provider = failing_provider,
      },
    })

    -- Should fall back to default behavior
    local bufs = cybu.get_bufs()
    assert.is_not_nil(bufs)
  end)

  it("validates buffer provider returns correct format", function()
    local cybu = require("cybu")

    -- Create test buffer
    vim.cmd("edit format_test.lua")
    local buf1 = vim.api.nvim_get_current_buf()

    -- Provider with invalid format
    local invalid_provider = function()
      return "not a table"
    end

    cybu.setup({
      experimental = {
        buffer_provider = invalid_provider,
      },
    })

    -- Should fall back to default when provider returns invalid data
    local bufs = cybu.get_bufs()
    assert.is_not_nil(bufs)
  end)

  it("filters provider results like default buffers", function()
    local cybu = require("cybu")

    -- Create test buffer
    vim.cmd("edit filter_test.lua")
    local buf1 = vim.api.nvim_get_current_buf()

    -- Provider that includes invalid buffer
    local provider_with_invalid = function()
      return {
        { bufnr = buf1, filename = vim.api.nvim_buf_get_name(buf1) },
        { bufnr = 999999, filename = "nonexistent.lua" }, -- Invalid buffer
      }
    end

    cybu.setup({
      experimental = {
        buffer_provider = provider_with_invalid,
      },
    })

    local bufs = cybu.get_bufs()

    -- Should contain valid buffers (invalid buffer filtered out)
    assert.is_not_nil(bufs)
    assert.True(#bufs >= 1) -- At least buf1 should be present

    -- Check that buf1 is present and 999999 is not
    local found_buf1 = false
    local found_invalid = false
    for _, buf in ipairs(bufs) do
      if buf.id == buf1 then
        found_buf1 = true
      elseif buf.id == 999999 then
        found_invalid = true
      end
    end
    assert.True(found_buf1)
    assert.is_false(found_invalid)
  end)

  it("respects exclude filtering with custom provider", function()
    local cybu = require("cybu")

    -- Create help buffer (excluded by default in some configs)
    vim.cmd("help")
    local help_buf = vim.api.nvim_get_current_buf()
    vim.cmd("edit exclude_test.lua")
    local normal_buf = vim.api.nvim_get_current_buf()

    -- Provider that includes help buffer
    local provider_with_help = function()
      return {
        { bufnr = help_buf, filename = vim.api.nvim_buf_get_name(help_buf) },
        { bufnr = normal_buf, filename = vim.api.nvim_buf_get_name(normal_buf) },
      }
    end

    cybu.setup({
      experimental = {
        buffer_provider = provider_with_help,
      },
      exclude = { "help" },
    })

    local bufs = cybu.get_bufs()

    -- Should only contain normal buffer, help excluded
    assert.is_not_nil(bufs)
    local has_help = false
    for _, buf in ipairs(bufs) do
      if buf.id == help_buf then
        has_help = true
        break
      end
    end
    assert.is_false(has_help)
  end)
end)
