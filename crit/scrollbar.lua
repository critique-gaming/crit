--- Scroll bars.
-- @module crit.scrollbar
-- @todo

local M = {
  default_gui_action_to_position = function (action)
    return action.x, action.y
  end,
  click_action_id = hash("touch"),
}

local h_scrollbar = hash("scrollbar")

local empty = {}

local function action_to_vec3(action)
  return vmath.vector3(action.screen_x, action.screen_y, 0)
end

function M.new(scroll, node, opts)
  opts = opts or empty
  local self = {
    action_to_position = opts.action_to_position or M.default_gui_action_to_position,
    node = node,
  }

  local knob = opts.knob or false
  local axis = opts.axis or "y"
  local is_vertical = axis == "y"
  local other_axis = is_vertical and "x" or "y"
  local invert_if_horizontal = is_vertical and 1 or -1
  local grab = nil

  self.size = gui.get_size(node)
  self.top = gui.get_position(node)

  if opts.spread then
    self.size[axis] = opts.spread
  end

  local hitbox_thickness_padding = opts.hitbox_thickness_padding

  local function on_offset_change()
    local progress = 0
    local height = 1

    local content_height = scroll.content_height
    local view_height = scroll.view_height
    local padding_bottom = scroll.padding_bottom
    local offset = scroll.offset
    offset = math.max(0, offset)
    offset = math.min(content_height + padding_bottom - view_height, offset)
    if content_height > view_height then
      progress = offset / (content_height + padding_bottom - view_height)
      height = view_height / (content_height + padding_bottom)
    end

    local size = self.size

    if knob then
      local delta = vmath.vector3()
      delta[axis] = invert_if_horizontal * (-progress * size[axis])
      gui.set_position(node, self.top + delta)
    else
      local delta = vmath.vector3()
      delta[axis] = invert_if_horizontal * (-progress * size[axis] * (1 - height))
      gui.set_position(node, self.top + delta)

      local new_size = vmath.vector3(size)
      new_size[axis] = new_size[axis] * height
      gui.set_size(node, new_size)
    end
  end

  scroll.add_offset_listener(on_offset_change)

  local function get_scroll_scale()
    local content_height = scroll.content_height
    local view_height = scroll.view_height
    local padding_bottom = scroll.padding_bottom

    local full_scroll_height = content_height + padding_bottom
    if knob then
      full_scroll_height = full_scroll_height - view_height
    end

    local size = self.size
    if hitbox_thickness_padding then
      size = vmath.vector3(size)
      size[other_axis] = size[other_axis] + hitbox_thickness_padding
    end

    local orig_pos = gui.get_position(node)
    local orig_screen_pos = gui.get_screen_position(node)
    gui.set_position(node, orig_pos + size)
    local size_in_screen = gui.get_screen_position(node) - orig_screen_pos
    gui.set_position(node, orig_pos)

    return full_scroll_height / size_in_screen[axis], size_in_screen
  end

  function self.set_metrics(top, size)
    self.top = top or self.top
    self.size = size or self.size
    on_offset_change()
  end

  function self.on_input(action_id, action)
    if action_id == M.click_action_id then
      if action.pressed then
        grab = nil
        local content_height = scroll.content_height
        local view_height = scroll.view_height

        if content_height <= view_height then
          return
        end

        if gui.pick_node(node, self.action_to_position(action)) then
          if scroll.acquire_control(h_scrollbar) then
            local node_pos = gui.get_screen_position(node)
            grab = invert_if_horizontal * (node_pos - action_to_vec3(action))[axis]
            return true
          end
        else
          local offset = scroll.offset

          local scale, size_in_screen = get_scroll_scale()
          local current_grab = gui.get_screen_position(node) - action_to_vec3(action)

          local dx = current_grab[other_axis]
          local half_width = size_in_screen[other_axis] * 0.5
          if dx < -half_width or dx > half_width then
            return
          end

          -- TODO: Check vertical bounds. Not needed for the question list, though
          if scroll.acquire_control(h_scrollbar) then
            scroll.set_offset(offset + scale * invert_if_horizontal * current_grab[axis])
            grab = 0
          end
        end
      elseif grab then
        local offset = scroll.offset

        if scroll.content_height <= scroll.view_height then
          return
        end

        local scale = get_scroll_scale()
        local current_grab = invert_if_horizontal * (
          (gui.get_screen_position(node) - action_to_vec3(action))[axis]
        )

        scroll.set_offset(offset + scale * (current_grab - grab))

        if action.released then
          scroll.release_control()
          grab = nil
        end
        return true
      end
    end
  end

  on_offset_change()
  return self
end

return M
