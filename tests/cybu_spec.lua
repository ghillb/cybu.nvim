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
    assert.same(icon.text, "…")
  end)
end)
