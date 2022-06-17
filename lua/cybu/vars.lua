local vars = {}

vars.mode = { default = "default", last_used = "last_used" }
vars.direction = { next = "next", prev = "prev" }
vars.style_path = { absolute = "absolute", relative = "relative", tail = "tail" }
vars.pos_relative_to = { win = "win", editor = "editor", cursor = "cursor" }
vars.pos_anchor = {
  topleft = function(args)
    local row = args.offset.vertical
    local col = args.offset.horizontal
    return { row = row, col = col, anchor = "NW" }
  end,
  topcenter = function(args)
    local row = args.offset.vertical
    local col = args.frame_width / 2 - args.max_view_width / 2 + args.offset.horizontal
    return { row = row, col = col, anchor = "NW" }
  end,
  topright = function(args)
    local row = args.offset.vertical
    local col = args.frame_width - args.offset.horizontal
    return { row = row, col = col, anchor = "NE" }
  end,
  bottomleft = function(args)
    local row = args.frame_height - vim.opt.cmdheight:get() - args.offset.vertical
    local col = args.offset.horizontal
    return { row = row, col = col, anchor = "SW" }
  end,
  bottomcenter = function(args)
    local row = args.frame_height - vim.opt.cmdheight:get() - args.offset.vertical
    local col = args.frame_width / 2 - args.max_view_width / 2 + args.offset.horizontal
    return { row = row, col = col, anchor = "SW" }
  end,
  bottomright = function(args)
    local row = args.frame_height - vim.opt.cmdheight:get() - args.offset.vertical
    local col = args.frame_width - args.offset.horizontal
    return { row = row, col = col, anchor = "SE" }
  end,
  centerleft = function(args)
    local row = args.frame_height / 2 - #args.cybu_view / 2 + args.offset.vertical
    local col = args.offset.horizontal
    return { row = row, col = col, anchor = "NW" }
  end,
  center = function(args)
    local row = args.frame_height / 2 - #args.cybu_view / 2 + args.offset.vertical
    local col = args.frame_width / 2 - args.max_view_width / 2 + args.offset.horizontal
    return { row = row, col = col, anchor = "NW" }
  end,
  centerright = function(args)
    local row = args.frame_height / 2 - #args.cybu_view / 2 + args.offset.vertical
    local col = args.frame_width - args.offset.horizontal
    return { row = row, col = col, anchor = "NE" }
  end,
}

return vars
