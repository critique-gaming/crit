--- Keyboard/gamepad focus state.
-- @module crit.input_state
-- @todo

local INPUT_METHOD_KEYBOARD = 0
local INPUT_METHOD_GAMEPAD = 1
local INPUT_METHOD_MOUSE = 2

local input_state = {
  input_method = INPUT_METHOD_MOUSE,

  INPUT_METHOD_KEYBOARD = INPUT_METHOD_KEYBOARD,
  INPUT_METHOD_GAMEPAD = INPUT_METHOD_GAMEPAD,
  INPUT_METHOD_MOUSE = INPUT_METHOD_MOUSE,
}

function input_state.switch_input_method(input_method)
  input_state.input_method = input_method
end

function input_state.new_focus_context()
  return {
    something_is_focused = false,
    focus_attempt_input_method = nil,
    focus_attempt_caused_by_user = true,
  }
end

input_state.default_focus_context = input_state.new_focus_context()

return input_state
