local c = require("cybu.config")
local plenary_loaded, strings = pcall(require, "plenary.strings")

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

utils.get_icon = load_once(function()
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
      if plenary_loaded and (strings.strdisplaywidth(icon) > 1) then
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

return utils
