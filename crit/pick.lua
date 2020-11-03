--- Sprite picking.
-- One-function module that tells you if a point falls inside of a sprite or not.
-- @module crit.pick

local M = {}

local h_size = hash("size")

local no_padding = {
  left = 0,
  right = 0,
  bottom = 0,
  top = 0,
}

--[[--
  Pick a sprite.

  **Limitations:**

  * The sprite must be positioned at the origin of its parent game object.
  * The sprite must not be rotated inside of its parent game object.
  * The sprite must not be scaled inside of its parent game object.
]]
-- @param[type=url | string] sprite_url An URL identifying the sprite component.
-- @number x The x position of the point (in world space) to do the check on.
-- @number y The y position of the point (in world space) to do the check on.
-- @tparam[opt] PickPadding padding By how much should the hitbox of the sprite
--   be expanded or constricted.
-- @treturn boolean Returns `true` if the point hits inside the sprite and
--   `false` otherwise.
function M.pick_sprite(sprite_url, x, y, padding)
  local transform = go.get_world_transform(sprite_url)
  local pos = vmath.inv(transform) * vmath.vector4(x, y, 0, 1)
  x, y = pos.x, pos.y

  local size = go.get(sprite_url, h_size)
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

---Padding table
-- @table PickPadding
-- @number left Left padding.
-- @number right Right padding.
-- @number top Top padding.
-- @number bottom Bottom padding.

return M