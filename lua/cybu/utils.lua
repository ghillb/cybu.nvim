local c = require("cybu.config")
local has_plenary, strings = pcall(require, "plenary.strings")

---@class CybuUtils
local utils = {}

utils.strlen = function(str)
  return #str:gsub("[\128-\191]", "")
end

-- got this from the awesome telescope/utils
local load_once = function(f)
  local resolved = nil
  return function(...)
    if resolved == nil then
      resolved = f()
    end

    ---@diagnostic disable-next-line: need-check-nil
    return resolved(...)
  end
end

local function adjust_absolute_path_head_for_windows(path)
  return path:sub(1, 1) .. ":" .. path:sub(2, -1)
end

local function has_windows()
  return vim.fn.has("win32") == 1
end

utils.get_icon_or_separator = load_once(function()
  local has_devicons, devicons = pcall(require, "nvim-web-devicons")

  if has_devicons then
    if not devicons.has_loaded() then
      devicons.setup()
    end

    return function(filename, devicons_enabled)
      if not devicons_enabled or not filename then
        return { text = c.opts.style.separator }
      end

      local icon, highlight = devicons.get_icon(filename, string.match(filename, "%a+$"), { default = true })

      -- truncate some ambiwidth icons when plenary is installed
      if has_plenary and c.opts.style.devicons.truncate and (strings.strdisplaywidth(icon) > 1) then
        icon = strings.truncate(icon, 1)
      end

      if c.opts.style.devicons.colored then
        return { text = icon, highlight = highlight }
      else
        return { text = icon }
      end
    end
  else
    return function(_, _)
      return { text = c.opts.style.separator }
    end
  end
end)

function utils.shorten_path(path)
  local Path = require("plenary.path")
  path = Path:new(path)

  local shortened_path = path:shorten(1)

  if has_windows() and path:is_absolute() then
    return adjust_absolute_path_head_for_windows(shortened_path)
  else
    return shortened_path
  end
end

function utils.get_relative_path(path, cwd_path)
  if has_windows() then
    cwd_path = cwd_path:gsub("\\", "/")
    path = path:gsub("\\", "/")
  end
  return string.gsub(path, cwd_path, "")
end

function utils.is_filter_active()
  return vim.tbl_contains(c.opts.exclude, vim.bo.filetype)
    or vim.tbl_contains({ "nofile" }, vim.bo.buftype)
    or not vim.bo.buflisted
end

return utils
