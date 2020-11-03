--- Scroll views.
-- @module crit.scroll
-- @todo

local filters = require "crit.filters"
local Inertia = require "crit.inertia"

local filter = filters.low_pass(3.0)

local Scroll = {
  click_action_id = hash("touch"),
  wheel_up_action_id = hash("mouse_wheel_up"),
  wheel_down_action_id = hash("mouse_wheel_down"),
}

local h_wheel = hash("wheel")
local h_touch = hash("touch")

local f_true = function () return true end

function Scroll.default_gui_action_to_dy(action)
  return action.screen_dy
end

function Scroll.default_go_action_to_dy(action)
  return action.dy
end

function Scroll.new(opts)
  opts = opts or {}
  local is_go = opts.is_go or false

  local self = {
    content_height = opts.content_height or 0,
    view_height = opts.view_height or 0,
    padding_bottom = opts.padding_bottom or 0,
    offset = opts.offset or 0,
    wheel_step = opts.wheel_step or 40,
    sender = nil,
    pick = opts.pick or f_true,
    on_capture_touch = opts.on_capture_touch or f_true,
    action_to_dy = opts.action_to_dy or (
      is_go and Scroll.default_go_action_to_dy or Scroll.default_gui_action_to_dy
    ),
  }

  local nodes = {}
  local offset_listeners = {}
  local interrupt_cb = nil
  local touch_dy = 0
  local touch_attempt = false
  local inertia = Inertia.new({ scalar = true })
  local panned = 0
  local animation = nil

  function self.set_content_height(content_height)
    self.content_height = content_height
    self.set_offset(self.offset, true, true)
  end

  function self.set_view_height(view_height)
    self.view_height = view_height
    self.set_offset(self.offset, true, true)
  end

  function self.set_padding_bottom(padding_bottom)
    self.padding_bottom = padding_bottom
    self.set_offset(self.offset, true, true)
  end

  function self.acquire_control(sender, interrupt_callback)
    if self.content_height <= self.view_height then
      return false
    end

    local old_interrupt_cb = interrupt_cb
    if self.sender and not (old_interrupt_cb and old_interrupt_cb(sender)) then
      return false
    end

    self.sender = sender
    interrupt_cb = interrupt_callback
    return true
  end

  function self.release_control()
    self.sender = nil
  end

  function self.add_offset_listener(listener)
    table.insert(offset_listeners, listener)
  end

  function self.add_node(node, position)
    position = position or (is_go
      and go.get_position(node)
      or gui.get_position(node)
    )
    local index = table.insert(nodes, { node, position })
    if is_go then
      go.set_position(position + vmath.vector3(0, self.offset, 0), node)
    else
      gui.set_position(node, position + vmath.vector3(0, self.offset, 0))
    end
    return index
  end

  function self.remove_node(node)
    for index, node_spec in ipairs(nodes) do
      if node_spec[1] == node then
        table.remove(nodes, index)
        return
      end
    end
  end

  function self.remove_all_nodes()
    nodes = {}
  end

  local function linear(x)
    return x
  end

  function self.animate_offset(offset, duration, easing)
    local interrupt_callback = function ()
      animation = nil
      return true -- The animation is always interruptible by other senders (like scrollwheel)
    end

    if not self.acquire_control("animation", interrupt_callback) then
      return false
    end

    animation = {
      progress = 0,
      from = self.offset,
      to = offset or 0,
      duration = duration or 0.5,
      easing = easing or linear
    }
    return true
  end

  function self.set_offset(offset, keep_velocity, allow_overscroll)
    local content_height = self.content_height
    local view_height = self.view_height
    if content_height < view_height then
      offset = 0
    end
    if not allow_overscroll then
      offset = math.min(offset, content_height + self.padding_bottom - view_height)
      offset = math.max(offset, 0)
    end
    self.offset = offset

    if not keep_velocity then
      panned = 0
      inertia.reset()
    end

    local voffset = vmath.vector3(0, offset, 0)
    for i, node in ipairs(nodes) do
      if is_go then
        go.set_position(node[2] + voffset, node[1])
      else
        gui.set_position(node[1], node[2] + voffset)
      end
    end

    for i, listener in ipairs(offset_listeners) do
      listener(self)
    end
  end

  function self.nearest_offset_covering_range(top, bottom)
    local offset = self.offset
    local content_height = self.content_height
    local view_height = self.view_height

    if offset + view_height < bottom then
      offset = bottom - view_height
    end
    if offset > top then
      offset = top
    end

    offset = math.min(offset, content_height + self.padding_bottom - view_height)
    offset = math.max(offset, 0)

    return offset
  end

  function self.update(dt)
    local anim = animation
    if anim then
      local progress = anim.progress + dt / anim.duration
      if progress >= 1 then
        progress = 1
        animation = nil
        self.release_control()
      end
      anim.progress = progress

      local alpha = anim.easing(progress)
      local offset = anim.from * (1 - alpha) + anim.to * alpha
      self.set_offset(offset)
    end

    local amount_panned = panned
    panned = 0
    local velocity_delta = inertia.update(dt, self.sender and amount_panned)

    if not self.sender then
      local max_offset = self.content_height + self.padding_bottom - self.view_height
      local offset = self.offset
      local offset_changed = false

      if offset < 0 or offset > max_offset then
        offset = filter(offset, offset < 0 and 0 or max_offset, dt)
        offset_changed = true
      end

      if velocity_delta and velocity_delta ~= 0 then
        offset = offset + velocity_delta
        offset_changed = true
      end

      if offset_changed then
        self.set_offset(offset, true, true)
      end
    end
  end

  function self.on_input(action_id, action)
    if action_id == Scroll.wheel_down_action_id or action_id == Scroll.wheel_up_action_id then
      if action.value > 0 and self.pick(action, self) and self.acquire_control(h_wheel) then
        local dy = action.value * (action_id == Scroll.wheel_down_action_id and self.wheel_step or -self.wheel_step)
        self.set_offset(self.offset + dy)
        self.release_control()
        return true
      end

    elseif action_id == Scroll.click_action_id then
      if self.sender ~= h_touch then -- If we still don't have control, try to acquire it
        if action.pressed then
          touch_dy = 0
          touch_attempt = self.pick(action, self)
          if self.sender == nil then
            panned = 0
            inertia.reset()
          end
        elseif touch_attempt and not action.released then
          local action_dy = self.action_to_dy(action)
          touch_dy = touch_dy + action_dy
          if math.abs(touch_dy) > 10 then
            touch_attempt = false
            if self.acquire_control(h_touch) then
              self.on_capture_touch()
            end
          end
        end
      end

      if self.sender == h_touch then -- If we have control, scroll
        local action_dy = self.action_to_dy(action)
        local dy = touch_dy + action_dy
        touch_dy = 0
        panned = panned + dy

        local max_offset = self.content_height + self.padding_bottom - self.view_height
        local offset = self.offset
        if offset < 0 or offset > max_offset then
          dy = dy * 0.5
        end

        self.set_offset(offset + dy, true, true)

        if action.released then
          self.release_control()
        end
        return true
      end

    elseif not action_id then
      if self.sender == h_touch then
        return true
      end

    end
  end

  return self
end

return Scroll
