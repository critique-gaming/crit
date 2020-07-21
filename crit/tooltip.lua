--- Tooltips
-- @module crit.tooltip
-- @todo

local Button = require "crit.button"
local Layout = require "crit.layout"
local dispatcher = require "crit.dispatcher"

local h_tooltip_show = hash("tooltip_show")
local h_tooltip_hide = hash("tooltip_hide")
local h_size = hash("size")
local h_tooltip_update_position = hash("tooltip_update_position")

local STATE_HOVER = Button.STATE_HOVER
local STATE_PRESSED = Button.STATE_PRESSED

local DISCARD_TOOLTIP = {}

local min = math.min
local max = math.max

local Tooltip = {
  PLACEMENT_RIGHT = 1,
  PLACEMENT_LEFT = 2,
  PLACEMENT_BOTTOM = 3,
  PLACEMENT_TOP = 4,
  DISCARD_TOOLTIP = DISCARD_TOOLTIP,

  default_padding = 20,
}

function Tooltip.scale_padding(padding)
  return padding * (Layout.viewport_width / Layout.design_width)
end

local function vmul (a, b)
  return vmath.vector3(a.x * b.x, a.y * b.y, a.z * b.z)
end

local function Tooltip__get_position(bounding_box, tooltip_size, placement, padding)
  local pad = Tooltip.scale_padding(padding or Tooltip.default_padding)
  local total_offset = (bounding_box.size + tooltip_size) * 0.5 + vmath.vector3(pad, pad, 0.0)

  local offset_attempts = {
    vmath.vector3(total_offset.x, 0.0, 0.0), -- right
    vmath.vector3(-total_offset.x, 0.0, 0.0), -- left
    vmath.vector3(0.0, -total_offset.y, 0.0), -- bottom
    vmath.vector3(0.0, total_offset.y, 0.0), -- top
  }

  if placement then
    offset_attempts = {offset_attempts[placement]}
  end

  -- Test if the tooltip fits on the screen at that offset
  local center = bounding_box.center
  local half_size_with_padding = tooltip_size * 0.5 + vmath.vector3(pad, pad, 0.0)
  for i, offset in ipairs(offset_attempts) do
    local position = center + offset
    local top_right = position + half_size_with_padding
    local bottom_left = position - half_size_with_padding
    if
      top_right.x <= Layout.viewport_width and
      top_right.y <= Layout.viewport_height and
      bottom_left.x >= 0.0 and
      bottom_left.y >= 0.0
    then
      return position
    end
  end

  local position = center + offset_attempts[1]
  return vmath.vector3(
    min(max(position.x, half_size_with_padding.x), Layout.viewport_width - half_size_with_padding.x),
    min(max(position.y, half_size_with_padding.y), Layout.viewport_height - half_size_with_padding.y),
    position.z
  )
end

local function nop() end

function Tooltip.new(options)
  local instances = {}
  local tooltip = {}

  local update = options.update
  local show = options.show
  local hide = options.hide

  function tooltip.show(text, message)
    local node, size, data

    local instance = instances[message.id]
    if instance then
      if update and update(instance, message, text) then
        instance.hiding = false
        return
      end
      if not instance.hiding then
        hide(instance, nop)
      end
    end

    local placement = message.placement
    local padding = message.padding or options.padding

    node, size, data = show(text, message)
    instances[message.id] = {
      node = node,
      size = size,
      data = data,
      placement = placement,
      padding = padding,
      hiding = false,
    }


    if node then
      local position = Tooltip__get_position(message.bounding_box, size, placement, padding)
      gui.set_position(node, position)
    end
  end

  function tooltip.hide(id)
    local instance = instances[id]
    if not instance then return end

    instance.hiding = true
    hide(instance, function ()
      if instances[id] == instance then
        instances[id] = nil
      end
    end)
  end

  function tooltip.hide_all()
    for id, instance in pairs(instances) do
      tooltip.hide(id)
    end
  end

  function tooltip.update_position(message)
    local id = message.id

    local instance = instances[id]
    if not instance then return end

    local node = instance.node
    if node then
      local size = instance.size
      local placement = message.placement or instance.placement
      local padding = message.padding or instance.padding or options.padding
      local position = Tooltip__get_position(message.bounding_box, size, placement, padding)
      gui.set_position(node, position)
    end
  end

  function tooltip.on_message(self, message_id, message, get_text)
    if message_id == h_tooltip_show then
      local text = get_text(self, message.payload, message.id)
      if text then
        tooltip.show(text, message)
      end

    elseif message_id == h_tooltip_hide then
      tooltip.hide(message.id)

    elseif message_id == h_tooltip_update_position then
      tooltip.update_position(message)
    end
  end

  local sub_id
  function tooltip.subscribe()
    sub_id = dispatcher.subscribe({ h_tooltip_show, h_tooltip_hide, h_tooltip_update_position })
    return sub_id
  end

  function tooltip.unsubscribe()
    if sub_id then
      dispatcher.unsubscribe(sub_id)
    end
  end

  return tooltip
end

function Tooltip.get_sprite_bounding_box(sprite, padding)
  local position = go.get_world_position(sprite)
  local scale = go.get_world_scale(sprite)
  local size = go.get(sprite, h_size)

  if padding then
    size = size + vmath.vector3(padding.right + padding.left, padding.bottom + padding.top, 0)
    position = position + vmul(vmath.vector3(
      (padding.right - padding.left) * 0.5,
      (padding.top - padding.bottom) * 0.5,
      0
    ), scale)
  end

  size = vmul(size, scale)
  size.x = size.x * Layout.camera_to_viewport_scale_x
  size.y = size.y * Layout.camera_to_viewport_scale_y

  position.x, position.y = Layout.camera_to_viewport(position.x, position.y)
  return { center = position, size = size }
end

local pivot_to_x = {
  [gui.PIVOT_CENTER] = 0.5,
  [gui.PIVOT_N] = 0.5,
  [gui.PIVOT_NE] = 1.0,
  [gui.PIVOT_E] = 1.0,
  [gui.PIVOT_SE] = 1.0,
  [gui.PIVOT_S] = 0.5,
  [gui.PIVOT_SW] = 0.0,
  [gui.PIVOT_W] = 0.0,
  [gui.PIVOT_NW] = 0.0,
}

local pivot_to_y = {
  [gui.PIVOT_CENTER] = 0.5,
  [gui.PIVOT_N] = 1.0,
  [gui.PIVOT_NE] = 1.0,
  [gui.PIVOT_E] = 0.5,
  [gui.PIVOT_SE] = 0.0,
  [gui.PIVOT_S] = 0.0,
  [gui.PIVOT_SW] = 0.0,
  [gui.PIVOT_W] = 0.5,
  [gui.PIVOT_NW] = 1.0,
}

function Tooltip.get_gui_node_bounding_box(node)
  local size = gui.get_size(node)
  local position = vmath.vector3()
  local pivot = gui.get_pivot(node)

  while node do
    local scale = gui.get_scale(node)
    size = vmul(size, scale)
    position = vmul(position, scale)
    position = position + gui.get_position(node)

    node = gui.get_parent(node)
  end

  return {
    center = position + vmath.vector3(
      (0.5 - pivot_to_x[pivot]) * size.x,
      (0.5 - pivot_to_y[pivot]) * size.y,
      0
    ),
    size = size
  }
end

function Tooltip.get_button_bounding_box(button)
  if button.is_sprite then
    return Tooltip.get_sprite_bounding_box(button.node, button.padding)
  end

  return Tooltip.get_gui_node_bounding_box(button.node)
end

local huge = math.huge
function Tooltip.merge_bounding_boxes(boxes)
  local min_x, max_x, min_y, max_y = huge, -huge, huge, -huge
  for _, box in ipairs(boxes) do
    local center = box.center
    local size = box.size
    local half_w, half_h = size.x * 0.5, size.y * 0.5
    local x, y = center.x, center.y
    local bmin_x, bmax_x = x - half_w, x + half_w
    local bmin_y, bmax_y = y - half_h, y + half_h

    if min_x > bmin_x then min_x = bmin_x end
    if max_x < bmax_x then max_x = bmax_x end
    if min_y > bmin_y then min_y = bmin_y end
    if max_y < bmax_y then max_y = bmax_y end
  end
  return {
    center = vmath.vector3((min_x + max_x) * 0.5, (min_y + max_y) * 0.5, 0.0),
    size = vmath.vector3(max_x - min_x, max_y - min_y, 0.0),
  }
end

local unique_id = 0
local function get_unique_id()
  unique_id = unique_id + 1
  return unique_id
end

function Tooltip.button_update_position(button, options)
  local tooltip_id = button.tooltip_id
  if not tooltip_id then return end

  dispatcher.dispatch(h_tooltip_update_position, {
    bounding_box = (options and options.get_bounding_box or button.tooltip_get_bounding_box)(button),
    placement = options and options.placement,
    padding = options and options.padding,
  })
end

function Tooltip.button_on_state_change(options)
  local id = options.id or get_unique_id()
  local payload = options.payload
  local get_bounding_box = options.get_bounding_box or Tooltip.get_button_bounding_box
  local placement = options.placement
  local padding = options.padding

  local is_payload_function = type(payload) == 'function'

  return function (button, state, old_state)
    local was_hover = old_state == STATE_HOVER or old_state == STATE_PRESSED
    local is_hover = state == STATE_HOVER or state == STATE_PRESSED
    if was_hover == is_hover then return end

    if is_hover then
      local sent_payload = payload
      if is_payload_function then
        sent_payload = payload()
      end
      if sent_payload ~= DISCARD_TOOLTIP then
        button.tooltip_id = id
        button.tooltip_get_bounding_box = get_bounding_box

        dispatcher.dispatch(h_tooltip_show, {
          id = id,
          payload = sent_payload,
          bounding_box = get_bounding_box(button),
          placement = placement,
          padding = padding,
        })
      end
    else
      button.tooltip_id = nil

      dispatcher.dispatch(h_tooltip_hide, { id = id })
    end
  end
end

return Tooltip
