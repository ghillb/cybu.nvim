-- @module cybu
local c = require("cybu.config")
local u = require("cybu.utils")
local v = require("cybu.vars")
local cybu, _state = {}, {}

--- Setup function to initialize cybu.
-- Call with config table or without to use default values.
-- @usage require'cybu'.setup()
-- @param[opt] user_config CybuOptions: Configuration table.
cybu.setup = function(user_config)
  vim.validate({ user_config = { user_config, "table", true } })
  c.load(user_config)
  _state.has_devicons = pcall(require, "nvim-web-devicons")
  if c.opts.style.devicons.enabled and not _state.has_devicons then
    vim.notify("Cybu: nvim-web-devicons enabled, but not installed\n", vim.log.levels.WARN)
  end
end

cybu.get_bufs = function()
  local bufs = {}
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    local buf_info = vim.fn.getbufinfo(id)[1]
    if buf_info.listed == 1 then
      table.insert(bufs, {
        id = id,
        name = buf_info.name,
      })
    end
  end

  if c.opts.style.path == v.style_path.absolute then
    return bufs
  end
  -- trim buf names
  local cwd_path = vim.fn.getcwd() .. "/"
  for _, b in ipairs(bufs) do
    if c.opts.style.path == v.style_path.relative then
      b.name = string.gsub(b.name, cwd_path, "")
    elseif c.opts.style.path == v.style_path.tail then
      b.name = vim.fn.fnamemodify(b.name, ":t")
    end
  end

  return bufs
end

cybu.load_target_buf = function(direction)
  if direction == v.direction.next then
    vim.cmd("bnext")
  elseif direction == v.direction.prev then
    vim.cmd("bprevious")
  else
    error("Invalid argument: '" .. direction .. "'. Allowed: " .. vim.inspect(v.direction))
  end
end

cybu.get_widths = function()
  local max_buf_id_width = 0
  local max_buf_name_width = 0
  local separator_width = 2 * #c.opts.style.separator
  local icon_width = 1

  if not _state.has_devicons or not c.opts.style.devicons.enabled then
    icon_width = 0
    separator_width = separator_width / 2
  end
  for _, b in ipairs(_state.bufs) do
    local buf_id_width = #tostring(b.id)
    local buf_name_width = #b.name
    max_buf_id_width = math.max(buf_id_width, max_buf_id_width)
    max_buf_name_width = math.max(buf_name_width, max_buf_name_width)
    b.buf_id_width = buf_id_width
    b.buf_name_width = buf_name_width
  end
  local max_entry_width = max_buf_id_width
    + max_buf_name_width
    + separator_width
    + icon_width
    + 2 * c.opts.style.padding

  -- max cybu win width
  local pos_relative_to = c.opts.position.relative_to
  local frame_width
  local max_win_width = c.opts.position.max_win_width
  if pos_relative_to == v.pos_relative_to.win or pos_relative_to == v.pos_relative_to.cursor then
    frame_width = vim.fn.winwidth(0)
  else
    frame_width = vim.o.columns
  end

  if max_win_width % 1 ~= 0 then
    max_win_width = math.ceil(max_win_width * frame_width)
  end
  return {
    entry = max_entry_width,
    win = math.min(max_win_width, max_entry_width),
    buf_id = max_buf_id_width,
    buf_name = max_buf_name_width,
    separator = separator_width,
    prefix = u.strlen(c.opts.style.prefix),
    icon = icon_width,
  }
end

cybu.get_entries = function()
  local entries = {}
  local pad_str = string.rep(" ", c.opts.style.padding)
  for i, b in ipairs(_state.bufs) do
    local buf_id = b.id
    local icon = u.get_icon(b.name, c.opts.style.devicons.enabled)
    if b.id == _state.current_buf then
      _state.focus = i
    end
    if b.buf_id_width < _state.widths.buf_id then
      buf_id = buf_id .. string.rep(" ", _state.widths.buf_id - b.buf_id_width)
    end
    local entry_width = _state.widths.buf_id
      + _state.widths.separator
      + _state.widths.icon
      + b.buf_name_width
      + 2 * c.opts.style.padding
    local entry = buf_id .. c.opts.style.separator

    if _state.has_devicons and c.opts.style.devicons.enabled then
      entry = entry .. icon.text .. c.opts.style.separator
    end
    if entry_width > _state.widths.win then
      entry = entry .. c.opts.style.prefix .. b.name:sub(entry_width + 1 + _state.widths.prefix - _state.widths.win)
    else
      entry = entry .. b.name
    end
    entry = pad_str .. entry .. pad_str
    if _state.widths.entry <= _state.widths.win and entry_width <= _state.widths.entry then
      entry = entry .. string.rep(" ", _state.widths.entry - entry_width)
    else
      entry = entry .. string.rep(" ", _state.widths.win - entry_width)
    end
    entries[i] = { entry = entry, bid = b.id, icon_highlight = icon.highlight }
  end
  return entries
end

cybu.get_view = function()
  local ecount = #_state.entries
  local win_height = math.min(ecount, c.opts.position.max_win_height)
  local view, offset1, offset2 = {}, 0, 1

  if win_height % 2 == 1 then
    offset1, offset2 = offset2, offset1
  end

  local first = _state.focus - (win_height - offset1) / 2 + offset2
  local last = _state.focus + (win_height - offset1) / 2

  for i = first, last do
    if i <= 0 then
      table.insert(view, _state.entries[i + ecount])
    elseif i > ecount then
      table.insert(view, _state.entries[i - ecount])
    else
      table.insert(view, _state.entries[i])
    end
  end

  return view
end

cybu.get_cybu_buf = function()
  local cybu_buf
  if not _state.cybu_buf then
    cybu_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(cybu_buf, "filetype", "cybu")
    vim.api.nvim_buf_set_option(cybu_buf, "buftype", "nofile")
    _state.cybu_ns = vim.api.nvim_create_namespace("cybu")
  else
    cybu_buf = _state.cybu_buf
  end

  for lnum, line in ipairs(_state.view) do
    vim.api.nvim_buf_set_lines(cybu_buf, lnum - 1, -1, true, { line.entry })
    if line.bid == _state.current_buf then
      vim.api.nvim_buf_add_highlight(cybu_buf, _state.cybu_ns, c.opts.style.highlights.current_buffer, lnum - 1, 0, -1)
    else
      vim.api.nvim_buf_add_highlight(
        cybu_buf,
        _state.cybu_ns,
        c.opts.style.highlights.adjacent_buffers,
        lnum - 1,
        0,
        -1
      )
    end

    if _state.has_devicons and c.opts.style.devicons.enabled and c.opts.style.devicons.colored then
      vim.api.nvim_buf_add_highlight(
        cybu_buf,
        _state.cybu_ns,
        line.icon_highlight,
        lnum - 1,
        _state.widths.buf_id + c.opts.style.padding,
        _state.widths.buf_id + c.opts.style.padding + _state.widths.separator + 3 * _state.widths.icon
      )
    end
  end
  return cybu_buf
end

cybu.get_cybu_win_pos = function()
  local frame_height, frame_width
  if c.opts.position.relative_to == v.pos_relative_to.cursor then
    return { row = 1, col = 0 }
  elseif c.opts.position.relative_to == v.pos_relative_to.win then
    frame_height = vim.fn.winheight(0)
    frame_width = vim.fn.winwidth(0)
  else
    frame_height = vim.o.lines
    frame_width = vim.o.columns
  end

  return v.pos_anchor[c.opts.position.anchor]({
    frame_height = frame_height,
    frame_width = frame_width,
    cybu_view = _state.view,
    max_view_width = _state.widths.win,
    offset = { vertical = c.opts.position.vertical_offset, horizontal = c.opts.position.horizontal_offset },
  })
end

cybu.show_cybu_win = function()
  local win_pos = cybu.get_cybu_win_pos()
  local win_opts = {
    relative = c.opts.position.relative_to,
    width = _state.widths.win,
    height = #_state.view,
    row = win_pos.row,
    col = win_pos.col,
    anchor = win_pos.anchor,
    style = "minimal",
    border = c.opts.style.border,
    focusable = false,
  }

  local function close_cybu_win()
    pcall(vim.api.nvim_win_close, _state.cybu_win_id, true)
    vim.api.nvim_exec_autocmds("User", { pattern = "CybuClose" })
    _state.cybu_win_id = nil
  end

  if _state.cybu_win_id and c.opts.position.relative_to == v.pos_relative_to.cursor then
    close_cybu_win()
  elseif _state.cybu_win_id then
    vim.api.nvim_win_set_config(_state.cybu_win_id, win_opts)
  end

  if not _state.cybu_win_id then
    _state.cybu_win_id = vim.api.nvim_open_win(_state.cybu_buf, false, win_opts)
    vim.api.nvim_exec_autocmds("User", { pattern = "CybuOpen" })
    vim.api.nvim_win_set_option(_state.cybu_win_id, "winhl", "NormalFloat:" .. c.opts.style.highlights.background)
    -- vim.api.nvim_win_set_option(state.cybu_win_id), "winbl", c.opts.style.winblend)
  end
  if _state.cybu_win_timer then
    _state.cybu_win_timer:stop()
  end
  _state.cybu_win_timer = vim.defer_fn(function()
    close_cybu_win()
  end, c.opts.display_time)
end

cybu.populate_state = function()
  _state.current_buf = vim.api.nvim_get_current_buf()
  _state.bufs = cybu.get_bufs()
  _state.widths = cybu.get_widths()
  _state.entries = cybu.get_entries()
  _state.view = cybu.get_view()
  _state.cybu_buf = cybu.get_cybu_buf()
end

--- Function to trigger buffer cycling into {direction}.
-- @usage require'cybu'.cycle(direction)
-- @param direction string: 'next' or 'prev'
cybu.cycle = function(direction)
  vim.validate({ direction = { direction, "string", false } })
  local filetype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "filetype")
  if vim.tbl_contains(c.opts.exclude, filetype) then
    return c.opts.fallback and c.opts.fallback()
  end
  cybu.load_target_buf(direction)
  cybu.populate_state()
  cybu.show_cybu_win()
end

return cybu
