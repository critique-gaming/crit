local input_state = require "crit.input_state"
local Button = require "crit.button"
local analog_to_digital = require "crit.analog_to_digital"

local INPUT_METHOD_KEYBOARD = input_state.INPUT_METHOD_KEYBOARD
local INPUT_METHOD_GAMEPAD = input_state.INPUT_METHOD_GAMEPAD

local NAVIGATE_CONFIRM = Button.NAVIGATE_CONFIRM

local FocusGiver = { __index = {} }

function FocusGiver.new(opts)
  local allow_gamepad_empty_focus = opts and opts.allow_gamepad_empty_focus
  if allow_gamepad_empty_focus == nil then
    allow_gamepad_empty_focus = false
  end

  local allow_keyboard_empty_focus = opts and opts.allow_keyboard_empty_focus
  if allow_keyboard_empty_focus == nil then
    allow_keyboard_empty_focus = true
  end

  local self = {
    focus_context = opts.focus_context or input_state.default_focus_context,
    allow_gamepad_empty_focus = allow_gamepad_empty_focus,
    allow_keyboard_empty_focus = allow_keyboard_empty_focus,
    on_pass_focus = opts.on_pass_focus,
  }
  setmetatable(self, FocusGiver)

  return self
end

local function FocusGiver_pass_focus(self, input_method, nav_action)
  local focus_context = self.focus_context
  local focus_attempt_input_method = focus_context.focus_attempt_input_method
  local focus_attempt_caused_by_user = focus_context.focus_attempt_caused_by_user
  local something_is_focused = focus_context.something_is_focused

  local should_switch = false
  if input_method then
    should_switch = true
    focus_context.focus_attempt_input_method = input_method
    focus_context.focus_attempt_caused_by_user = true
  else
    input_method = focus_attempt_input_method or input_state.input_method
    focus_context.focus_attempt_caused_by_user = false
  end
  focus_context.something_is_focused = true
  local did_focus = self:on_pass_focus(nav_action, input_method)
  focus_context.focus_attempt_input_method = focus_attempt_input_method
  focus_context.focus_attempt_caused_by_user = focus_attempt_caused_by_user
  if not did_focus then
    focus_context.something_is_focused = something_is_focused
  end

  if did_focus and should_switch then
    input_state.switch_input_method(input_method)
  end
  return did_focus
end

function FocusGiver.__index:try_focus_first(nav_action)
  if self.focus_context.something_is_focused then
    return false
  end

  local allow_empty_focus = true
  local input_method = self.focus_context.focus_attempt_input_method or input_state.input_method
  if input_method == INPUT_METHOD_GAMEPAD then
    allow_empty_focus = self.allow_gamepad_empty_focus
  elseif input_method == INPUT_METHOD_KEYBOARD then
    allow_empty_focus = self.allow_keyboard_empty_focus
  end

  if allow_empty_focus then
    return true -- We get initial focus
  end

  if nav_action then
    if type(nav_action) == "table" then
      for i, dir in ipairs(nav_action) do
        if FocusGiver_pass_focus(self, nil, dir) then
          return true
        end
      end
      return FocusGiver_pass_focus(self, nil, nil)
    else
      return FocusGiver_pass_focus(self, nil, nav_action) or FocusGiver_pass_focus(self, nil, nil)
    end
  end
  return FocusGiver_pass_focus(self, nil, nil)
end

FocusGiver.__index.on_input = analog_to_digital.convert_on_input(function (self, action_id, action)
  if self.focus_context.something_is_focused or not action_id then
    return
  end

  if not (action.pressed or action.repeated) then return end

  local nav_action, is_gamepad = Button.action_id_to_navigation_action(action_id)

  -- We are interested only in directional actions
  if nav_action == nil or nav_action == NAVIGATE_CONFIRM then
    return
  end

  local allow_empty_focus
  if is_gamepad then
    allow_empty_focus = self.allow_gamepad_empty_focus
  else
    allow_empty_focus = self.allow_keyboard_empty_focus
  end

  if not allow_empty_focus then
    return
  end

  return FocusGiver_pass_focus(self,
    is_gamepad and INPUT_METHOD_GAMEPAD or INPUT_METHOD_KEYBOARD,
    nav_action
  )
end)

return FocusGiver
