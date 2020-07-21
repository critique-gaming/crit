--- Buttons.
-- @module crit.button
-- @todo

local pick = require "crit.pick"
local input_state = require "crit.input_state"
local analog_to_digital = require "crit.analog_to_digital"
local sys_config = require "crit.sys_config"
local colors = require "crit.colors"

local INPUT_METHOD_KEYBOARD = input_state.INPUT_METHOD_KEYBOARD
local INPUT_METHOD_GAMEPAD = input_state.INPUT_METHOD_GAMEPAD

local h_colorx = hash("color.x")
local h_tintx = hash("tint.x")
local h_colory = hash("color.y")
local h_tinty = hash("tint.y")
local h_colorz = hash("color.z")
local h_tintz = hash("tint.z") local h_colorw = hash("color.w")
local h_tintw = hash("tint.w")
local h_touch = hash("touch")
local h_key_up = hash("key_up")
local h_key_down = hash("key_down")
local h_key_left = hash("key_left")
local h_key_right = hash("key_right")
local h_key_space = hash("key_space")
local h_key_enter = hash("key_enter")
local h_enable = hash("enable")
local h_disable = hash("disable")
local h_gamepad_lpad_up = hash("gamepad_lpad_up")
local h_gamepad_lpad_down = hash("gamepad_lpad_down")
local h_gamepad_lpad_left = hash("gamepad_lpad_left")
local h_gamepad_lpad_right = hash("gamepad_lpad_right")
local h_gamepad_lstick_digital_up = hash("gamepad_lstick_digital_up")
local h_gamepad_lstick_digital_down = hash("gamepad_lstick_digital_down")
local h_gamepad_lstick_digital_left = hash("gamepad_lstick_digital_left")
local h_gamepad_lstick_digital_right = hash("gamepad_lstick_digital_right")
local h_gamepad_rpad_down = hash("gamepad_rpad_down")
local h_tint = hash("tint")
local h_color = hash("color")

local default_action_to_position = function (action)
  return action.x, action.y
end

local STATE_DEFAULT = 0
local STATE_PRESSED = 1
local STATE_HOVER = 2
local STATE_DISABLED = 3

local NAVIGATE_UP = 0
local NAVIGATE_DOWN = 1
local NAVIGATE_LEFT = 2
local NAVIGATE_RIGHT = 3
local NAVIGATE_CONFIRM = 4

local KEYBOARD = 0
local GAMEPAD = 8

local CLICK = 5
local KEYBOARD_UP = KEYBOARD + NAVIGATE_UP
local KEYBOARD_DOWN = KEYBOARD + NAVIGATE_DOWN
local KEYBOARD_LEFT = KEYBOARD + NAVIGATE_LEFT
local KEYBOARD_RIGHT = KEYBOARD + NAVIGATE_RIGHT
local KEYBOARD_CONFIRM = KEYBOARD + NAVIGATE_CONFIRM
local GAMEPAD_UP = GAMEPAD + NAVIGATE_UP
local GAMEPAD_DOWN = GAMEPAD + NAVIGATE_DOWN
local GAMEPAD_LEFT = GAMEPAD + NAVIGATE_LEFT
local GAMEPAD_RIGHT = GAMEPAD + NAVIGATE_RIGHT
local GAMEPAD_CONFIRM = GAMEPAD + NAVIGATE_CONFIRM

local input_map = {
  [h_touch] = CLICK,
  [h_key_space] = KEYBOARD_CONFIRM,
  [h_key_enter] = KEYBOARD_CONFIRM,
  [h_key_up] = KEYBOARD_UP,
  [h_key_down] = KEYBOARD_DOWN,
  [h_key_left] = KEYBOARD_LEFT,
  [h_key_right] = KEYBOARD_RIGHT,
  [h_gamepad_rpad_down] = GAMEPAD_CONFIRM,
  [h_gamepad_lpad_up] = GAMEPAD_UP,
  [h_gamepad_lpad_down] = GAMEPAD_DOWN,
  [h_gamepad_lpad_left] = GAMEPAD_LEFT,
  [h_gamepad_lpad_right] = GAMEPAD_RIGHT,
  [h_gamepad_lstick_digital_up] = GAMEPAD_UP,
  [h_gamepad_lstick_digital_down] = GAMEPAD_DOWN,
  [h_gamepad_lstick_digital_left] = GAMEPAD_LEFT,
  [h_gamepad_lstick_digital_right] = GAMEPAD_RIGHT,
}

local Button = {
  default_gui_action_to_position = default_action_to_position,
  default_sprite_action_to_position = default_action_to_position,
  input_map = input_map,

  STATE_DEFAULT = STATE_DEFAULT,
  STATE_PRESSED = STATE_PRESSED,
  STATE_HOVER = STATE_HOVER,
  STATE_DISABLED = STATE_DISABLED,

  NAVIGATE_UP = NAVIGATE_UP,
  NAVIGATE_DOWN = NAVIGATE_DOWN,
  NAVIGATE_LEFT = NAVIGATE_LEFT,
  NAVIGATE_RIGHT = NAVIGATE_RIGHT,
  NAVIGATE_CONFIRM = NAVIGATE_CONFIRM,

  CLICK = CLICK,
  KEYBOARD_UP = KEYBOARD_UP,
  KEYBOARD_DOWN = KEYBOARD_DOWN,
  KEYBOARD_LEFT = KEYBOARD_LEFT,
  KEYBOARD_RIGHT = KEYBOARD_RIGHT,
  KEYBOARD_CONFIRM = KEYBOARD_CONFIRM,
  GAMEPAD_UP = GAMEPAD_UP,
  GAMEPAD_DOWN = GAMEPAD_DOWN,
  GAMEPAD_LEFT = GAMEPAD_LEFT,
  GAMEPAD_RIGHT = GAMEPAD_RIGHT,
  GAMEPAD_CONFIRM = GAMEPAD_CONFIRM,
}

local Button_default_on_pass_focus
local Button_on_input
local Button_supports_focus
local Button_focus
local Button_unfocus
local Button_set_state

local function nop() end

local function resolve_callback(f)
  if not f then return nop end
  if type(f) == "table" then
    return function (...)
      for i = 1, #f do
        f[i](...)
      end
    end
  end
  return f
end

function Button.new(node, self)
  self = self or {}

  self.node = node

  local is_sprite = self.is_sprite or false
  self.is_sprite = is_sprite

  self.state = self.starts_enabled == false and STATE_DISABLED or STATE_DEFAULT
  self.mouse_can_press = false
  self.mouse_down = false
  self.confirm_down_action = nil
  self.focused = false
  self.triggered_action = false

  self.keyboard_focus = self.keyboard_focus or false
  self.gamepad_focus = self.gamepad_focus or false
  self.focus_context = self.focus_context or input_state.default_focus_context
  self.on_pass_focus = self.on_pass_focus or Button_default_on_pass_focus

  if self.keep_hover == nil then
    self.keep_hover = true
  end

  self.padding = self.padding or {
    left = self.padding_left or 0,
    right = self.padding_right or 0,
    top = self.padding_top or 0,
    bottom = self.padding_bottom or 0,
  }

  self.action_to_position = self.action_to_position or (is_sprite and
    Button.default_sprite_action_to_position or
    Button.default_gui_action_to_position
  )

  self.pick = self.pick or (is_sprite and
    Button.default_sprite_pick or
    Button.default_gui_pick
  )

  local shortcut_actions = {}
  if self.shortcut_actions then
    for i, action_id in ipairs(self.shortcut_actions) do
      shortcut_actions[action_id] = true
    end
  end
  self._shortcut_actions = shortcut_actions

  local on_state_change = resolve_callback(self.on_state_change)
  local on_focus_change = resolve_callback(self.on_focus_change)

  if self.focus_simulates_hover then
    self.on_state_change = function (button, button_state, old_state)
      if button.focused then
        if button_state == STATE_DEFAULT then
          button_state = STATE_HOVER
        end
        if old_state == STATE_DEFAULT then
          old_state = STATE_HOVER
        end
        if button_state == old_state then
          return
        end
      end
      return on_state_change(button, button_state, old_state)
    end

    self.on_focus_change = function (button, focused)
      if focused then
        on_state_change(button, STATE_HOVER, button.state)
      else
        on_state_change(button, button.state, STATE_HOVER)
      end
      on_focus_change(button, focused)
    end
  else
    self.on_state_change = on_state_change
    self.on_focus_change = on_focus_change
  end

  function self.focus()
    if self.state == STATE_DISABLED then
      return false
    end

    if self.focused then
      return true
    end

    if not Button_supports_focus(self) then
      return false
    end

    self.focus_context.something_is_focused = true
    Button_focus(self)
    return true
  end

  function self.cancel_focus()
    if self.focused then
      self.focus_context.something_is_focused = false
      Button_unfocus(self)
    end
  end

  function self.switch_input_method()
    if input_state.input_method ~= input_state.INPUT_METHOD_MOUSE then
      self.cancel_touch()
    end
    if self.focused and not Button_supports_focus(self) then
      self.cancel_focus()
    end
  end

  function self.cancel_touch()
    if self.state == STATE_DISABLED then
      return
    end
    self.mouse_down = false
    self.mouse_can_press = false
    if not self.confirm_down_action then
      Button_set_state(self, STATE_DEFAULT)
    end
  end

  function self.set_enabled(enabled)
    if enabled == (self.state ~= STATE_DISABLED) then
      return
    end

    if not enabled then
      self.cancel_focus()
    end

    Button_set_state(self, enabled and STATE_DEFAULT or STATE_DISABLED)

    if not enabled then
      self.mouse_can_press = false
      self.mouse_down = false
      self.confirm_down_action = nil
    end
  end

  function self.on_input(action_id, action)
    if self.state == STATE_DISABLED then
      return
    end

    return analog_to_digital.convert_action(self, action_id, action, Button_on_input)
  end

  if not self.skip_initial_state_change then
    self:on_state_change(self.state)
  end

  function self.refresh_state()
    self:on_state_change(self.state, self.state)
  end

  return self
end

function Button_set_state(self, state)
  local old_state = self.state
  if state ~= old_state then
    self:on_state_change(state, old_state)
    self.state = state
  end
end

function Button_focus(self)
  self.focused = true
  self:on_focus_change(true)
end

function Button_unfocus(self)
  if self.confirm_down_action then
    self.cancel_touch()
  end
  self.focused = false
  self:on_focus_change()
end

function Button_supports_focus(self)
  local supports_focus = false
  local input_method = self.focus_context.focus_attempt_input_method or input_state.input_method
  if input_method == INPUT_METHOD_GAMEPAD then
    supports_focus = self.gamepad_focus
  elseif input_method == INPUT_METHOD_KEYBOARD then
    supports_focus = self.keyboard_focus
  end
  return supports_focus
end

local function Button_pass_focus(self, input_method, nav_action)
  local focus_context = self.focus_context
  local focus_attempt_input_method = focus_context.focus_attempt_input_method
  local something_is_focused = focus_context.something_is_focused

  if not input_method then
    focus_context.something_is_focused = false
    if self:on_pass_focus(nav_action, input_state.input_method or focus_attempt_input_method) then
      Button_unfocus(self)
      return true
    end
    focus_context.something_is_focused = something_is_focused
    return false
  end

  focus_context.focus_attempt_input_method = input_method
  focus_context.something_is_focused = false
  local did_focus = self:on_pass_focus(nav_action, input_method)
  focus_context.focus_attempt_input_method = focus_attempt_input_method

  if did_focus then
    input_state.switch_input_method(input_method)
    Button_unfocus(self)
    return true
  end
  focus_context.something_is_focused = something_is_focused
  return false
end

local function Button_mapped_action_id_to_navigation_action(mapped_action_id)
  local is_gamepad = mapped_action_id >= GAMEPAD
  local nav_action = mapped_action_id - (is_gamepad and GAMEPAD or KEYBOARD)
  return nav_action, is_gamepad
end

function Button.action_id_to_navigation_action(action_id)
  if not action_id then return nil, false end
  local mapped_action_id = input_map[action_id]
  if not mapped_action_id or mapped_action_id == CLICK then
    return nil, false
  end
  return Button_mapped_action_id_to_navigation_action(mapped_action_id)
end

function Button_on_input(self, action_id, action)
  local confirm_down_action = self.confirm_down_action

  if action_id == nil and not confirm_down_action then
    if not sys_config.is_mobile or action.virtual_cursor then
      if self.mouse_down then
        return not not self.action and self.mouse_can_press
      end
      local is_hovering = self:pick(action)
      Button_set_state(self, is_hovering and STATE_HOVER or STATE_DEFAULT)
    end

  elseif action_id == confirm_down_action then
    if action.released then
      self.confirm_down_action = nil
      self.triggered_action = true
      Button_set_state(self, STATE_DEFAULT)
      self.triggered_action = false
      if self.action then self:action(false, action_id) end
    else
      Button_set_state(self, STATE_PRESSED)
    end
    return true

  else
    local mapped_action_id = input_map[action_id]

    if mapped_action_id == CLICK then
      if confirm_down_action then return end

      local is_hovering = self:pick(action)
      if action.released then
        if self.mouse_down then
          self.mouse_down = false

          local has_mouse = not sys_config.is_mobile or action.virtual_cursor

          local triggered_action = self.mouse_can_press and self.action and is_hovering
          local new_state
          if triggered_action then
            new_state = (has_mouse and self.keep_hover) and STATE_HOVER or STATE_DEFAULT
          else
            new_state = (has_mouse and is_hovering) and STATE_HOVER or STATE_DEFAULT
          end

          self.mouse_can_press = false
          self.triggered_action = triggered_action
          Button_set_state(self, new_state)
          self.triggered_action = false
          if triggered_action then
            self:action(true, action_id)
            return true
          end
        end
      else
        if action.pressed then
          self.mouse_can_press = is_hovering
          self.mouse_down = true
        end
        if self.mouse_down then
          local mouse_can_press = self.mouse_can_press
          if mouse_can_press or self.hover_from_external_touch then
            local new_state = is_hovering
              and ((self.mouse_can_press and self.action)
                and STATE_PRESSED
                or STATE_HOVER
              )
              or STATE_DEFAULT
            Button_set_state(self, new_state)
          elseif not mouse_can_press and self.state == STATE_HOVER then
            Button_set_state(self, STATE_DEFAULT)
          end
        end
      end
      return not not self.action and self.mouse_can_press

    elseif self.focused and mapped_action_id then
      local nav_action, is_gamepad = Button_mapped_action_id_to_navigation_action(mapped_action_id)

      if nav_action == NAVIGATE_CONFIRM then
        if action.pressed and self.action and not self.mouse_can_press then
          self.confirm_down_action = action_id
          Button_set_state(self, STATE_PRESSED)
          return true
        end
      elseif action.pressed or action.repeated then
        local input_method = is_gamepad and INPUT_METHOD_GAMEPAD or INPUT_METHOD_KEYBOARD
        return Button_pass_focus(self, input_method, nav_action)
      end

    elseif action.pressed and self.action and not self.mouse_can_press and self._shortcut_actions[action_id] then
      self.confirm_down_action = action_id
      Button_set_state(self, STATE_PRESSED)
      return true
    end
  end
end

function Button.set_input_map(new_input_map)
  input_map = new_input_map
  Button.input_map = input_map
end

function Button.default_sprite_pick(self, action)
  local node = self.node
  if not node then return false end
  local x, y = self.action_to_position(action)
  return pick.pick_sprite(node, x, y, self.padding)
end
function Button.default_gui_pick(self, action)
  local node = self.node
  if not node then return false end
  return gui.pick_node(node, self.action_to_position(action))
end

function Button_default_on_pass_focus()
  return false
end

function Button.focus_ring(node, is_sprite)
  if is_sprite then
    go.set(node, h_tintw, 0.0)
    msg.post(node, h_disable)
  else
    local color = gui.get_color(node)
    color.w = 0.0
    gui.set_color(node, color)
    gui.set_enabled(node, false)
  end

  return function (self, focused)
    local focus_duration = self.focus_duration or 0.2

    if self.is_sprite then
      if focused then
        msg.post(node, h_enable)
        go.cancel_animations(node, h_tintw)
        go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 1.0, go.EASING_LINEAR, focus_duration)
      else
        go.cancel_animations(node, h_tintw)
        go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_LINEAR, focus_duration, 0.0, function ()
          go.set(node, h_tintw, 0.0)
          msg.post(node, h_disable)
        end)
      end

    else
      if focused then
        gui.set_enabled(node, true)
        gui.cancel_animation(node, h_colorw)
        gui.animate(node, h_colorw, 1.0, go.EASING_LINEAR, focus_duration)
      else
        gui.cancel_animation(node, h_colorw)
        gui.animate(node, h_colorw, 0.0, go.EASING_LINEAR, focus_duration, 0.0, function ()
          gui.set_enabled(node, false)
        end)
      end
    end
  end
end

local function resolve_duration(duration, state, old_state)
  if type(duration) == "function" then
    return duration(state, old_state)
  end
  if not old_state then
    return 0.0
  end
  return duration or 0.2
end

local function run_animations(button, options, value, duration, animate_sprite, animate_label, animate_node)
  local nodes = options and options.nodes
  if nodes then
    for i = 1, #nodes do
      animate_node(nodes[i], value, duration)
    end
  else
    local node = options and options.node or (not button.is_sprite and button.node)
    if node then
      animate_node(node, value, duration)
    end
  end

  local labels = options and options.labels
  if labels then
    for i = 1, #labels do
      animate_label(labels[i], value, duration)
    end
  else
    local label = options and options.label
    if label then
      animate_label(label, value, duration)
    end
  end

  local sprites = options and options.sprites
  if sprites then
    for i = 1, #sprites do
      animate_sprite(sprites[i], value, duration)
    end
  else
    local sprite = options and options.sprite or (button.is_sprite and button.node)
    if sprite then
      animate_sprite(sprite, value, duration)
    end
  end
end

local function resolve_value(values, state, button)
  if not values then return nil end
  if type(values) == "function" then
    return values(state, button)
  end
  return values[state]
end

Button.default_fade_alpha = {
  [STATE_DEFAULT] = 1.0,
  [STATE_PRESSED] = 0.4,
  [STATE_HOVER] = 0.6,
  [STATE_DISABLED] = 0.4
}

local function fade_sprite(node, value, duration)
  go.cancel_animations(node, h_tintw)
  go.animate(node, h_tintw, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function fade_label(node, value, duration)
  go.cancel_animations(node, h_colorw)
  go.animate(node, h_colorw, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function fade_node(node, value, duration)
  gui.cancel_animation(node, h_colorw)
  gui.animate(node, h_colorw, value, gui.EASING_LINEAR, duration)
end

function Button.fade(options)
  return function (self, state, old_state)
    local value = resolve_value(options and options.alpha, state, self) or Button.default_fade_alpha[state]
    local duration = resolve_duration(options and options.duration, state, old_state)

    run_animations(self, options, value, duration, fade_sprite, fade_label, fade_node)
  end
end

Button.default_darken_brightness = {
  [STATE_DEFAULT] = 1.0,
  [STATE_PRESSED] = 0.4,
  [STATE_HOVER] = 0.6,
  [STATE_DISABLED] = 0.4
}

local function darken_sprite(sprite, value, duration)
  go.cancel_animations(sprite, h_tintx)
  go.cancel_animations(sprite, h_tinty)
  go.cancel_animations(sprite, h_tintz)
  go.animate(sprite, h_tintx, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
  go.animate(sprite, h_tinty, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
  go.animate(sprite, h_tintz, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function darken_label(node, value, duration)
  go.cancel_animations(node, h_colorx)
  go.cancel_animations(node, h_colory)
  go.cancel_animations(node, h_colorz)
  go.animate(node, h_colorx, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
  go.animate(node, h_colory, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
  go.animate(node, h_colorz, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function darken_node(node, value, duration)
  gui.cancel_animation(node, h_colorx)
  gui.cancel_animation(node, h_colory)
  gui.cancel_animation(node, h_colorz)
  gui.animate(node, h_colorx, value, gui.EASING_LINEAR, duration)
  gui.animate(node, h_colory, value, gui.EASING_LINEAR, duration)
  gui.animate(node, h_colorz, value, gui.EASING_LINEAR, duration)
end

function Button.darken(options)
  return function (self, state, old_state)
    local value = resolve_value(options and options.brightness, state, self) or Button.default_darken_brightness[state]
    local duration = resolve_duration(options and options.duration, state, old_state)

    run_animations(self, options, value, duration, darken_sprite, darken_label, darken_node)
  end
end

Button.default_tint_color = {
  [STATE_DEFAULT] = colors.white,
  [STATE_PRESSED] = colors.gray(0.4),
  [STATE_HOVER] = colors.gray(0.6),
  [STATE_DISABLED] = colors.gray(0.4),
}

local function tint_sprite(node, value, duration)
  go.cancel_animations(node, h_tint)
  go.animate(node, h_tint, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function tint_label(node, value, duration)
  go.cancel_animations(node, h_color)
  go.animate(node, h_color, go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, duration)
end

local function tint_node(node, value, duration)
  gui.cancel_animation(node, h_color)
  gui.animate(node, h_color, value, gui.EASING_LINEAR, duration)
end

function Button.tint(options)
  return function (self, state, old_state)
    local value = resolve_value(options and options.color, state, self) or Button.default_tint_color[state]
    local duration = resolve_duration(options and options.duration, state, old_state)

    run_animations(self, options, value, duration, tint_sprite, tint_label, tint_node)
  end
end

function Button.flipbook(options)
  return function (self, state)
    local animation = options and (options[state] or options[STATE_DEFAULT])
    if animation then
      if self.is_sprite then
        sprite.play_flipbook(self.node, animation)
      else
        gui.play_flipbook(self.node, animation)
      end
    end
  end
end

return Button
