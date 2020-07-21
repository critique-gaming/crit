--- Mouse cursor hiding manager.
-- @module crit.cursor
-- @todo

local M = {
  PRIORITY_DEFAULT = 0,
  PRIORITY_INPUT_METHOD = 1,
  PRIORITY_SCENE_LOW = 9,
  PRIORITY_SCENE = 10,
  PRIORITY_SCENE_HIGH = 11,
  PRIORITY_PAUSE_MENU = 20,
  PRIORITY_IMPORTANT = 30,
}

local visible_ranks = {
  [M.PRIORITY_DEFAULT] = true,
}

function M.get_visible()
  local top_priority = -1
  local top_value = true
  for prio, val in pairs(visible_ranks) do
    if prio > top_priority then
      top_priority = prio
      top_value = val
    end
  end

  return top_value
end

function M.set_visible(value, priority)
  visible_ranks[priority or M.PRIORITY_SCENE] = value

  if defos then
    defos.set_cursor_visible(M.get_visible())
  end
end

return M
