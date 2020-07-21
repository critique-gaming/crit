--- Color manipulation utilities.
-- @module crit.colors
-- @todo

local vec4 = vmath.vector4

local M = {
  white = vec4(1.0, 1.0, 1.0, 1.0),
  black = vec4(0.0, 0.0, 0.0, 1.0),
  transparent_white = vec4(1.0, 1.0, 1.0, 0.0),
  transparent_black = vec4(0.0, 0.0, 0.0, 0.0),
}
M.transparent = M.transparent_black

local inv_255 = 1.0 / 255.0
local inv_15 = 1.0 / 15.0
function M.from_hex(hex)
  hex = hex:gsub("^#","")

  local r, g, b, a
  a = 1.0

  local len = #hex

  if len == 6 or len == 8 then
    r = tonumber("0x" .. hex:sub(1, 2)) * inv_255
    g = tonumber("0x" .. hex:sub(3, 4)) * inv_255
    b = tonumber("0x" .. hex:sub(5, 6)) * inv_255
    if len == 8 then
      a = tonumber("0x" .. hex:sub(7, 8)) * inv_255
    end
    return vec4(r, g, b, a)
  end

  if len == 3 or len == 4 then
    r = tonumber("0x" .. hex:sub(1, 1)) * inv_15
    g = tonumber("0x" .. hex:sub(2, 2)) * inv_15
    b = tonumber("0x" .. hex:sub(3, 3)) * inv_15
    if len == 4 then
      a = tonumber("0x" .. hex:sub(4, 4)) * inv_15
    end
    return vec4(r, g, b, a)
  end

  error("Invalid color format: " .. hex)
end

local min = math.min
local max = math.max

local function component_to_hex(x)
  return ("%02X"):format(max(0, min(255, x * 255)))
end

function M.to_hex(color)
  return "#" ..
    component_to_hex(color.x) ..
    component_to_hex(color.y) ..
    component_to_hex(color.z) ..
    component_to_hex(color.w)
end

function M.vmul(a, b)
  return vec4(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w)
end

function M.darken(color, brightness)
  return vec4(color.x * brightness, color.y * brightness, color.z * brightness, color.w)
end

function M.fade(color, alpha)
  return vec4(color.x, color.y, color.z, color.w * alpha)
end

function M.with_alpha(color, alpha)
  return vec4(color.x, color.y, color.z, alpha)
end

function M.gray(value)
  return vec4(value, value, value, 1.0)
end

function M.gui_set_color_alpha(node, alpha)
  local color = gui.get_color(node)
  color.w = alpha
  gui.set_color(node, color)
end

function M.scale(value)
  return vmath.vector3(value, value, 1)
end

return M
