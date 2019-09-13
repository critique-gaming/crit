local M = {}

local h_size = hash("size")

local no_padding = {
  left = 0,
  right = 0,
  bottom = 0,
  top = 0,
}

function M.pick_sprite(url, x, y, padding)
  local transform = go.get_world_transform(url)
  local pos = vmath.inv(transform) * vmath.vector4(x, y, 0, 1)
  x, y = pos.x, pos.y

  local size = go.get(url, h_size)
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