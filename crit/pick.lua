local M = {}

local h_size = hash("size")

local no_padding = {
  left = 0,
  right = 0,
  bottom = 0,
  top = 0,
}

function M.pick_sprite(url, x, y, padding)
  local position = go.get_world_position(url)
  local scale = go.get_world_scale(url)
  local rotation = go.get_rotation(url) -- go.get_world_rotation seems to be broken when also scaling
  local size = go.get(url, h_size)

  -- Undo position
  x = x - position.x
  y = y - position.y

  -- Undo rotation
  local direction = vmath.rotate(rotation, vmath.vector3(1, 0, 0))
  local sin, cos = -direction.y, direction.x
  x, y = x * cos - y * sin, y * cos + x * sin

  -- Undo scale
  x = x / scale.x
  y = y / scale.y

  padding = padding or no_padding

  local half_width = size.x * 0.5
  local left = -half_width - padding.left
  local right = half_width + padding.right
  if x < left or x > right then return false end

  local half_height = size.y * 0.5
  local top = half_height + padding.top
  local bottom = -half_height - padding.bottom
  if y < bottom or y > top then return false end

  return true
end


return M