-- @module cybu
local c = require("cybu.config")
local u = require("cybu.utils")
local v = require("cybu.vars")
local infobar = require("cybu.infobar")
local cybu, _state = {}, {}
local has_plenary, strings = pcall(require, "plenary.strings")

--- Detect the UI client being used
-- @return string: 'neovide', 'nvim-qt', 'terminal', or 'unknown'
local function detect_ui_client()
  if vim.g.neovide then
    return "neovide"
  elseif vim.g.nvim_qt then
    return "nvim-qt"
  elseif vim.env.TERM or vim.env.TERM_PROGRAM then
    return "terminal"
  else
    return "unknown"
  end
end

--- Setup function to initialize cybu.
-- Call with config table or without to use default values.
-- @usage require'cybu'.setup()
-- @param[opt] user_config CybuOptions: Configuration table.
cybu.setup = function(user_config)
  vim.validate({ user_config = { user_config, "table", true } })
  c.load(user_config)
  _state.has_devicons = pcall(require, "nvim-web-devicons")
  _state.buffer_touch_times = {}

  if c.opts.style.devicons.enabled and not _state.has_devicons then
    vim.notify("Cybu: nvim-web-devicons enabled, but not installed\n", vim.log.levels.WARN)
    if not has_plenary then
      vim.notify("Cybu: plenary.nvim needed, but not installed\n", vim.log.levels.ERROR)
    end
  end

  if c.opts.behavior.show_on_autocmd then
    vim.api.nvim_create_autocmd(c.opts.behavior.show_on_autocmd, {
      group = vim.api.nvim_create_augroup("cybu#show_on_autocmd", {}),
      callback = cybu.autocmd,
    })
  end

  local update_mode = c.opts.behavior.mode.last_used.update_on
  if update_mode == "cursor_moved" then
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = vim.api.nvim_create_augroup("cybu#cursor_tracking", {}),
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        _state.buffer_touch_times[buf] = vim.fn.localtime()
      end,
    })
  elseif update_mode == "text_changed" then
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = vim.api.nvim_create_augroup("cybu#text_tracking", {}),
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        _state.buffer_touch_times[buf] = vim.fn.localtime()
      end,
    })
  end
end

cybu.get_bufs = function()
  local bufs = {}
  _state.lookup = {}
  local cwd_path = vim.fn.getcwd() .. "/"

  local filtered_bids

  -- use experimental buffer provider if configured
  if c.opts.experimental.buffer_provider and type(c.opts.experimental.buffer_provider) == "function" then
    local success, provider_bufs = pcall(c.opts.experimental.buffer_provider)
    if success and provider_bufs and type(provider_bufs) == "table" then
      local bids = {}
      for _, buf_info in ipairs(provider_bufs) do
        if buf_info.bufnr and vim.api.nvim_buf_is_valid(buf_info.bufnr) then
          -- apply same filtering as default provider
          if vim.fn.buflisted(buf_info.bufnr) == 1 then
            if not vim.tbl_contains(c.opts.exclude, vim.api.nvim_buf_get_option(buf_info.bufnr, "filetype")) then
              table.insert(bids, buf_info.bufnr)
            end
          end
        end
      end

      filtered_bids = bids
    else
      vim.notify("Cybu: experimental buffer_provider failed, falling back to default", vim.log.levels.WARN)
      filtered_bids = nil
    end
  end

  if not filtered_bids then
    filtered_bids = vim.tbl_filter(function(id)
      if 1 ~= vim.fn.buflisted(id) then
        return false
      end
      if vim.tbl_contains(c.opts.exclude, vim.api.nvim_buf_get_option(id, "filetype")) then
        return false
      end
      return true
    end, vim.api.nvim_list_bufs())
  end

  if _state.mode == "last_used" then
    if
      c.opts.behavior.mode.last_used.update_on == "cursor_moved"
      or c.opts.behavior.mode.last_used.update_on == "text_changed"
    then
      -- sort by cursor-based touch times
      table.sort(filtered_bids, function(a, b)
        local touch_a = _state.buffer_touch_times[a] or 0
        local touch_b = _state.buffer_touch_times[b] or 0
        return touch_a > touch_b
      end)
    else
      -- use default vim lastused behavior
      table.sort(filtered_bids, function(a, b)
        return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
      end)
    end
  end

  for i, id in ipairs(filtered_bids) do
    local name = vim.fn.bufname(id)

    -- adjust buf names
    if c.opts.style.path == v.style_path.absolute then
      name = vim.fn.fnamemodify(name, ":p")
    elseif c.opts.style.path == v.style_path.relative then
      name = u.get_relative_path(name, cwd_path)
    elseif c.opts.style.path == v.style_path.tail then
      name = vim.fn.fnamemodify(name, ":t")
    elseif c.opts.style.path == v.style_path.tail_dir then
      local tail = vim.fn.fnamemodify(name, ":t")
      local dir = vim.fn.fnamemodify(name, ":h:t")
      name = dir .. "/" .. tail
    end

    if c.opts.style.path_abbreviation == v.style_path_abbreviation.shortened then
      name = u.shorten_path(name)
    end

    table.insert(bufs, {
      id = id,
      name = name,
      icon = u.get_icon_or_separator(name, c.opts.style.devicons.enabled),
    })
    _state.lookup[id] = i
  end

  return bufs
end

cybu.load_target_buf = function()
  local target = _state.bufs[_state.focus]
  return target and vim.api.nvim_win_set_buf(0, target.id)
end

cybu.get_widths = function()
  local max_buf_id_width = 0
  local max_buf_name_width = 0
  local max_icon_width = 0
  local separator_width = #c.opts.style.separator
  if not c.opts.style.hide_buffer_id and _state.has_devicons and c.opts.style.devicons.enabled then
    separator_width = separator_width * 2
  elseif c.opts.style.hide_buffer_id and not (c.opts.style.devicons.enabled and _state.has_devicons) then
    separator_width = 0
  end

  for _, b in ipairs(_state.bufs) do
    b.buf_id_width = #tostring(b.id)
    b.buf_name_width = #b.name
    b.buf_icon_width = has_plenary and strings.strdisplaywidth(b.icon.text) or 1
    max_buf_id_width = math.max(b.buf_id_width, max_buf_id_width)
    max_buf_name_width = math.max(b.buf_name_width, max_buf_name_width)
    max_icon_width = math.max(b.buf_icon_width, max_icon_width)
  end

  if not _state.has_devicons or not c.opts.style.devicons.enabled then
    max_icon_width = 0
  end

  if c.opts.style.hide_buffer_id then
    max_buf_id_width = 0
  end

  local max_entry_width = max_buf_id_width
    + max_buf_name_width
    + separator_width
    + max_icon_width
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
    icon = max_icon_width,
  }
end

cybu.get_entries = function()
  local entries = {}
  local pad_str = string.rep(" ", c.opts.style.padding)
  for i, b in ipairs(_state.bufs) do
    local bid = b.id
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

    if _state.has_devicons and has_plenary and c.opts.style.devicons.enabled then
      entry = entry .. b.icon.text .. string.rep(" ", _state.widths.icon - b.buf_icon_width) .. c.opts.style.separator
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
    entries[i] = { entry = entry, bid = b.id, icon_highlight = b.icon.highlight }
  end
  return entries
end

cybu.get_view = function()
  if _state.is_rolling_view then
    local view, offset1, offset2 = {}, 0, 1

    if _state.win_height % 2 == 1 then
      offset1, offset2 = offset2, offset1
    end

    local first = _state.focus - (_state.win_height - offset1) / 2 + offset2
    local last = _state.focus + (_state.win_height - offset1) / 2

    for i = first, last do
      if i <= 0 then
        table.insert(view, _state.entries[i + _state.bcount])
      elseif i > _state.bcount then
        table.insert(view, _state.entries[i - _state.bcount])
      else
        table.insert(view, _state.entries[i])
      end
    end
    return view
  else
    local first = (_state.frame_nr - 1) * c.opts.position.max_win_height + 1
    local last = _state.frame_nr * c.opts.position.max_win_height
    return vim.list_slice(_state.entries, first, last)
  end
end

cybu.get_cybu_buf = function()
  local cybu_buf
  if not _state.cybu_buf or not vim.api.nvim_buf_is_valid(_state.cybu_buf) then
    cybu_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(cybu_buf, "filetype", "cybu")
    vim.api.nvim_buf_set_option(cybu_buf, "buftype", "nofile")
    _state.cybu_ns = vim.api.nvim_create_namespace("cybu")
  else
    cybu_buf = _state.cybu_buf
  end

  local lnum_highlight_current_buf
  if _state.is_rolling_view then
    lnum_highlight_current_buf = math.ceil(_state.win_height / 2) - 1
  else
    lnum_highlight_current_buf = (_state.focus - 1) % _state.win_height
  end

  for lnum, line in ipairs(_state.view) do
    vim.api.nvim_buf_set_lines(cybu_buf, lnum - 1, -1, true, { line.entry })

    if lnum - 1 ~= lnum_highlight_current_buf then
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
        _state.widths.buf_id + c.opts.style.padding + _state.widths.separator + 3
      )
    end
  end

  vim.api.nvim_buf_add_highlight(
    cybu_buf,
    _state.cybu_ns,
    c.opts.style.highlights.current_buffer,
    lnum_highlight_current_buf,
    0,
    -1
  )

  if c.opts.style.infobar.enabled then
    vim.api.nvim_buf_set_lines(cybu_buf, -1, -1, true, { _state.infobar })
    vim.api.nvim_buf_add_highlight(
      cybu_buf,
      _state.cybu_ns,
      c.opts.style.highlights.infobar,
      #vim.api.nvim_buf_get_lines(cybu_buf, 0, -1, false) - 1,
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
  local ui_client = detect_ui_client()

  local win_opts = {
    relative = c.opts.position.relative_to,
    width = _state.widths.win,
    height = #_state.view + (c.opts.style.infobar.enabled and 1 or 0),
    row = win_pos.row,
    col = win_pos.col,
    anchor = win_pos.anchor,
    style = "minimal",
    border = c.opts.style.border,
    focusable = false,
  }

  -- UI-specific adjustments
  if ui_client == "neovide" then
    -- Neovide specific adjustments for better rendering
    win_opts.zindex = 100
  elseif ui_client == "nvim-qt" then
    -- nvim-qt specific adjustments
    win_opts.zindex = 50
  elseif ui_client == "terminal" then
    -- Terminal-specific optimizations
    if vim.env.TERM_PROGRAM == "WezTerm" or vim.env.TERM_PROGRAM == "Alacritty" then
      -- Modern terminal emulators handle floating windows better
      win_opts.zindex = 75
    end
  end

  local function close_cybu_win()
    pcall(vim.api.nvim_win_close, _state.cybu_win_id, true)
    vim.api.nvim_exec_autocmds("User", { pattern = "CybuClose" })
    _state.cybu_win_id = nil
    _state.focus = nil
  end

  if _state.cybu_win_id and c.opts.position.relative_to == v.pos_relative_to.cursor then
    close_cybu_win()
  elseif _state.cybu_win_id then
    vim.api.nvim_win_set_config(_state.cybu_win_id, win_opts)
  end

  if not _state.cybu_win_id then
    local success, win_id = pcall(vim.api.nvim_open_win, _state.cybu_buf, false, win_opts)

    if success and win_id then
      _state.cybu_win_id = win_id
      vim.api.nvim_exec_autocmds("User", { pattern = "CybuOpen" })
      local win_hl_success = pcall(
        vim.api.nvim_win_set_option,
        _state.cybu_win_id,
        "winhl",
        string.format(
          "NormalFloat:%s,FloatBorder:%s",
          c.opts.style.highlights.background,
          c.opts.style.highlights.border
        )
      )
      if not win_hl_success then
        vim.notify("Cybu: Failed to set window highlights, continuing with defaults", vim.log.levels.DEBUG)
      end
    else
      -- Floating window failed, fallback to buffer switching only
      vim.notify("Cybu: Floating window unavailable, switching buffer directly", vim.log.levels.DEBUG)
      cybu.load_target_buf()
      return -- Exit early, no UI to show
    end
  end

  if _state.cybu_win_timer then
    _state.cybu_win_timer:stop()
  end
  _state.cybu_win_timer = vim.defer_fn(function()
    if _state.switch_on_close then
      cybu.load_target_buf()
    end
    close_cybu_win()
  end, c.opts.display_time)
end

cybu.populate_state = function(args)
  _state.is_rolling_view = c.opts.behavior.mode.default.view == v.behavior.view_type.rolling
      and _state.mode == v.mode.default
    or c.opts.behavior.mode.last_used.view == v.behavior.view_type.rolling and _state.mode == v.mode.last_used

  _state.switch_on_close = c.opts.behavior.mode.default.switch == v.behavior.switch_mode.on_close
      and _state.mode == v.mode.default
    or c.opts.behavior.mode.last_used.switch == v.behavior.switch_mode.on_close and _state.mode == v.mode.last_used

  _state.current_buf = vim.api.nvim_get_current_buf()
  _state.increment = _state.direction == v.direction.next and 1 or -1
  _state.bufs = not _state.focus and cybu.get_bufs() or _state.bufs
  _state.bcount = #_state.bufs
  if _state.bcount == 0 then
    vim.notify("Cybu: No switchable buffers", vim.log.levels.INFO)
    return false
  end
  _state.win_height = math.min(_state.bcount, c.opts.position.max_win_height)
  _state.frame_count = math.ceil(_state.bcount / c.opts.position.max_win_height)
  if args and args.is_auto_cmd_call then
    _state.is_rolling_view = c.opts.behavior.mode.auto.view == v.behavior.view_type.rolling
    _state.focus = _state.lookup[_state.current_buf]
  else
    _state.focus = ((_state.focus or _state.lookup[_state.current_buf]) + _state.increment) % (_state.bcount + 1)
    _state.focus = (_state.focus ~= 0) and _state.focus or (_state.increment == 1 and 1 or _state.bcount)
  end
  _state.frame_nr = math.floor((_state.focus - 1) / _state.win_height) % _state.frame_count + 1
  _state.widths = cybu.get_widths()
  _state.entries = cybu.get_entries()
  _state.view = cybu.get_view()
  _state.infobar = c.opts.style.infobar.enabled and infobar.get_infobar(_state)
  _state.cybu_buf = cybu.get_cybu_buf()
  return true
end

--- Function to trigger buffer cycling into {direction}.
-- @usage require'cybu'.cycle(direction)
-- @param direction string: 'next' or 'prev'
-- @param mode string: 'default' or 'last_used'
cybu.cycle = function(direction, mode)
  vim.validate({ direction = { direction, "string", false } })
  if not vim.tbl_contains({ v.direction.next, v.direction.prev }, direction) then
    error("Invalid direction: " .. tostring(direction))
  end
  if u.is_filter_active() then
    return c.opts.fallback and c.opts.fallback(direction, mode)
  end
  _state.mode = mode or v.mode.default
  _state.direction = direction
  if not cybu.populate_state() then
    return
  end
  if not _state.switch_on_close then
    cybu.load_target_buf()
  end
  cybu.show_cybu_win()
end

cybu.autocmd = function()
  local _trigger = function()
    if u.is_filter_active() then
      return false
    end

    local status, _ = pcall(cybu.populate_state, { is_auto_cmd_call = true })

    if not status then
      -- vim.notify("Cybu: " .. err, vim.log.levels.ERROR) -- TODO: improve logging and error handling
      return false
    end
    cybu.show_cybu_win()
    return true
  end

  vim.defer_fn(_trigger, 1) -- NOTE: unhappy with this, but it works
end

return cybu
