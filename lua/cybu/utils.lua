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

local function adjust_absolute_path_head_for_os(path)
  if vim.fn.has('win32') then
    return path:sub(1, 1) .. ':' .. path:sub(2, -1)
  end
end

function utils.get_preffered_path_separator()
  if vim.fn.has('win32') == 1 then
    return '\\'
  else
    return '/'
  end
end

function utils.get_alternate_separator(sep)
  if sep == '\\' then
    return '/'
  else
    return '\\'
  end
end

function utils.shorten_path(path, preffered_separator)
  local get_first = function(path_elem)
    return path_elem:sub(1, 1)
  end

  local split_path = vim.fn.split(path, preffered_separator)
  local filename = split_path[#split_path]

  -- we remove the last element so that we don't have duplicated first letters of filenames later
  table.remove(split_path, #split_path)

  local shortened_path = table.concat(
    vim.tbl_map(get_first, split_path),
    preffered_separator
  )

  return
    adjust_absolute_path_head_for_os(shortened_path)
      .. preffered_separator
      .. filename
end


return utils
