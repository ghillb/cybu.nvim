local M = {}
M.get_infobar = function(state)
  local infobar = string.format("%s/%s:%d/%d", state.focus, state.bcount, state.frame_nr, state.frame_count)
  local padcount = math.max(0, state.widths.win - #infobar) / 2
  local offset = (padcount % 2 ~= 0) and 1 or 0

  infobar = string.rep(" ", padcount) .. infobar .. string.rep(" ", padcount)

  if infobar:len() > state.widths.win then
    infobar = infobar:sub(0, state.widths.win - 1) .. "…"
  elseif infobar:len() < state.widths.win then
    infobar = infobar .. string.rep(" ", offset)
  end
  return infobar
end
return M
