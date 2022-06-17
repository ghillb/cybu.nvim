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
  local cwd_path = vim.fn.getcwd() .. "/"
  local bids = vim.tbl_filter(function(id)
    if 1 ~= vim.fn.buflisted(id) then
      return false
    end
    return true
  end, vim.api.nvim_list_bufs())

  if _state.mode == "last_used" then
    table.sort(bids, function(a, b)
      return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
    end)
  end

  for _, id in ipairs(bids) do
    local name = vim.fn.bufname(id)
    -- trim buf names
    if c.opts.style.path == v.style_path.relative then
      name = string.gsub(name, cwd_path, "")
    elseif c.opts.style.path == v.style_path.tail then
      name = vim.fn.fnamemodify(name, ":t")
    end
    table.insert(bufs, {
      id = id,
      name = name,
    })
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
  local icon_width = 1
  local separator_width = #c.opts.style.separator
  if not c.opts.style.hide_buffer_id and _state.has_devicons and c.opts.style.devicons.enabled then
    separator_width = separator_width * 2
  elseif c.opts.style.hide_buffer_id and not (c.opts.style.devicons.enabled and _state.has_devicons) then
    separator_width = 0
  end

  if not _state.has_devicons or not c.opts.style.devicons.enabled then
    icon_width = 0
  end

  for _, b in ipairs(_state.bufs) do
    local buf_id_width = #tostring(b.id)
    local buf_name_width = #b.name
    max_buf_id_width = math.max(buf_id_width, max_buf_id_width)
    max_buf_name_width = math.max(buf_name_width, max_buf_name_width)
    b.buf_id_width = buf_id_width
    b.buf_name_width = buf_name_width
  end

  if c.opts.style.hide_buffer_id then
    max_buf_id_width = 0
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
    local bid = b.id
    local icon = u.get_icon(b.name, c.opts.style.devicons.enabled)
    if bid == _state.current_buf then
      _state.center = i
    end
    if b.buf_id_width < _state.widths.buf_id then
      bid = bid .. string.rep(" ", _state.widths.buf_id - b.buf_id_width)
    end
    local entry_width = _state.widths.buf_id
      + _state.widths.separator
      + _state.widths.icon
      + b.buf_name_width
      + 2 * c.opts.style.padding

    local entry = ""
    if not c.opts.style.hide_buffer_id then
      entry = bid .. c.opts.style.separator
    end

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
  _state.win_height = math.min(ecount, c.opts.position.max_win_height)
  local function create_default_view()
    local view, offset1, offset2 = {}, 0, 1

    if _state.win_height % 2 == 1 then
      offset1, offset2 = offset2, offset1
    end

    local first = _state.center - (_state.win_height - offset1) / 2 + offset2
    local last = _state.center + (_state.win_height - offset1) / 2

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

  if _state.mode == v.mode.default then
    return create_default_view()
  end

  local function create_last_used_view()
    _state.increment = _state.direction == v.direction.next and 1 or -1
    local frame_count = math.ceil(ecount / c.opts.position.max_win_height)
    local frame_nr = 1
    if _state.focus then
      frame_nr = math.floor((_state.focus + _state.increment) % ecount / _state.win_height) % frame_count + 1
      _state.focus = (_state.focus + _state.increment) % #_state.bufs
    else
      _state.focus = 1
    end
    local first = (frame_nr - 1) * c.opts.position.max_win_height + 1
    local last = frame_nr * c.opts.position.max_win_height
    return vim.list_slice(_state.entries, first, last)
  end

  if _state.mode == v.mode.last_used then
    return create_last_used_view()
  end
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
    if line.bid == _state.current_buf and _state.mode == v.mode.default then
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

  if _state.mode == v.mode.last_used then
    vim.api.nvim_buf_add_highlight(
      cybu_buf,
      _state.cybu_ns,
      c.opts.style.highlights.current_buffer,
      _state.focus % _state.win_height,
      0,
      -1
    )
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
    if _state.mode == v.mode.last_used then
      local target = _state.bufs[_state.focus + 1]
      _state.focus = nil
      return target and vim.api.nvim_win_set_buf(0, target.id)
    end
  end, c.opts.display_time)
end

cybu.populate_state = function()
  _state.current_buf = vim.api.nvim_get_current_buf()
  _state.bufs = (not _state.focus or _state.mode == v.mode.default) and cybu.get_bufs() or _state.bufs
  _state.widths = cybu.get_widths()
  _state.entries = cybu.get_entries()
  _state.view = cybu.get_view()
  _state.cybu_buf = cybu.get_cybu_buf()
end

--- Function to trigger buffer cycling into {direction}.
-- @usage require'cybu'.cycle(direction)
-- @param direction string: 'next' or 'prev'
-- @param mode string: 'default' or 'last_used'
cybu.cycle = function(direction, mode)
  vim.validate({ direction = { direction, "string", false } })
  local filetype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "filetype")
  if vim.tbl_contains(c.opts.exclude, filetype) then
    return c.opts.fallback and c.opts.fallback()
  end
  _state.mode = mode or v.mode.default
  _state.direction = direction
  if _state.mode == v.mode.default then
    cybu.load_target_buf(_state.direction)
  end
  cybu.populate_state()
  cybu.show_cybu_win()
end

return cybu
