local ScrollBar = {
  __index = {},
  default_gui_action_to_position = function (action)
    return action.x, action.y
  end,
  click_action_id = hash("touch"),
}

local h_scrollbar = hash("scrollbar")

local empty = {}

local function ScrollBar_on_offset_change(self)
  local progress = 0
  local height = 1

  local scroll = self.scroll
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

  local node = self.node
  local size = self.size
  local axis = self.axis

  if self.knob then
    local delta = vmath.vector3()
    delta[axis] = self._invert_if_horizontal(-progress * size[axis])
    gui.set_position(node, self.top + delta)
  else
    local delta = vmath.vector3()
    delta[axis] = self._invert_if_horizontal(-progress * size[axis] * (1 - height))
    gui.set_position(node, self.top + delta)

    local new_size = vmath.vector3(size)
    new_size[axis] = new_size[axis] * height
    gui.set_size(node, new_size)
  end
end

function ScrollBar.new(scroll, node, opts)
  opts = opts or empty
  local self = {
    scroll = scroll,
    node = node,
    knob = opts.knob or false,
    axis = opts.axis or "y",
    action_to_position = opts.action_to_position or ScrollBar.default_gui_action_to_position
  }

  local is_vertical = self.axis == "y"
  self.other_axis = is_vertical and "x" or "y"
  if is_vertical then
    function self._invert_if_horizontal(value)
      return value
    end
  else
    function self._invert_if_horizontal(value)
      return -value
    end
  end

  self.size = gui.get_size(node)
  self.top = gui.get_position(node)

  if opts.spread then
    self.size[self.axis] = opts.spread
  end

  scroll:add_offset_listener(function ()
    ScrollBar_on_offset_change(self)
  end)

  setmetatable(self, ScrollBar)

  ScrollBar_on_offset_change(self)

  return self
end

function ScrollBar.__index:set_metrics(top, size)
  self.top = top
  self.size = size
  ScrollBar_on_offset_change(self)
end

local function get_scroll_scale(self)
  local scroll = self.scroll
  local content_height = scroll.content_height
  local view_height = scroll.view_height
  local padding_bottom = scroll.padding_bottom

  local full_scroll_height = content_height + padding_bottom
  if self.knob then
    full_scroll_height = full_scroll_height - view_height
  end

  local node = self.node
  local orig_pos = gui.get_position(node)
  local orig_screen_pos = gui.get_screen_position(node)
  gui.set_position(node, orig_pos + self.size)
  local size_in_screen = gui.get_screen_position(node) - orig_screen_pos
  gui.set_position(node, orig_pos)

  return full_scroll_height / size_in_screen[self.axis], size_in_screen
end

local function action_to_vec3(action)
  return vmath.vector3(action.screen_x, action.screen_y, 0)
end

function ScrollBar.__index:on_input(action_id, action)
  if action_id == ScrollBar.click_action_id then
    if action.pressed then
      self.grab = nil
      local scroll = self.scroll
      local content_height = scroll.content_height
      local view_height = scroll.view_height

      if content_height <= view_height then
        return
      end

      if gui.pick_node(self.node, self.action_to_position(action)) then
        if self.scroll:acquire_control(h_scrollbar) then
          local node_pos = gui.get_screen_position(self.node)
          self.grab = self._invert_if_horizontal((node_pos - action_to_vec3(action))[self.axis])
          return true
        end
      else
        local offset = scroll.offset

        local scale, size_in_screen = get_scroll_scale(self)
        local current_grab = gui.get_screen_position(self.node) - action_to_vec3(action)

        local axis = self.axis
        local other_axis = self.other_axis

        local dx = current_grab[other_axis]
        local half_width = size_in_screen[other_axis] * 0.5
        if dx < -half_width or dx > half_width then
          return
        end

        -- TODO: Check vertical bounds. Not needed for the question list, though
        if self.scroll:acquire_control(h_scrollbar) then
          self.scroll:set_offset(offset + scale * self._invert_if_horizontal(current_grab[axis]))
          self.grab = 0
        end
      end
    elseif self.grab then
      local scroll = self.scroll
      local offset = scroll.offset

      if scroll.content_height <= scroll.view_height then
        return
      end

      local scale = get_scroll_scale(self)
      local current_grab = self._invert_if_horizontal(
        (gui.get_screen_position(self.node) - action_to_vec3(action))[self.axis]
      )

      scroll:set_offset(offset + scale * (current_grab - self.grab))

      if action.released then
        self.scroll:release_control()
        self.grab = nil
      end
      return true
    end
  end
end

return ScrollBar