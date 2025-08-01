---@class CybuConfig
local config = {}

--- @class CybuOptions
local default_config = {
  position = {
    relative_to = "win",
    anchor = "center",
    vertical_offset = -1,
    horizontal_offset = -1,
    max_win_height = 5,
    max_win_width = 0.5,
  },
  style = {
    path = "relative",
    path_abbreviation = "none",
    border = "single",
    separator = " ",
    prefix = "…",
    padding = 1,
    hide_buffer_id = false,
    devicons = {
      enabled = true,
      colored = true,
      truncate = true,
    },
    infobar = {
      enabled = false,
    },
    highlights = {
      current_buffer = "CybuFocus",
      adjacent_buffers = "CybuAdjacent",
      background = "CubuBackground",
      border = "CybuBorder",
      infobar = "CybuInfobar",
    },
  },
  behavior = {
    mode = {
      default = {
        switch = "immediate",
        view = "rolling",
      },
      last_used = {
        switch = "on_close",
        view = "paging",
        update_on = "buf_enter",
      },
      auto = {
        view = "rolling",
      },
    },
    show_on_autocmd = false,
  },
  experimental = {
    buffer_provider = nil,
  },
  display_time = 750,
  exclude = {},
  filter = {
    unlisted = true,
  },
  fallback = nil,
}

--- @type CybuOptions
config.opts = {}

config.load = function(user_config)
  config.opts = vim.tbl_deep_extend("force", default_config, user_config or {})
end

return config
