local h_gamepad_lstick_up = hash("gamepad_lstick_up")
local h_gamepad_lstick_digital_up = hash("gamepad_lstick_digital_up")
local h_gamepad_lstick_down = hash("gamepad_lstick_down")
local h_gamepad_lstick_digital_down = hash("gamepad_lstick_digital_down")
local h_gamepad_lstick_left = hash("gamepad_lstick_left")
local h_gamepad_lstick_digital_left = hash("gamepad_lstick_digital_left")
local h_gamepad_lstick_right = hash("gamepad_lstick_right")
local h_gamepad_lstick_digital_right = hash("gamepad_lstick_digital_right")
local h_gamepad_rstick_up = hash("gamepad_rstick_up")
local h_gamepad_rstick_digital_up = hash("gamepad_rstick_digital_up")
local h_gamepad_rstick_down = hash("gamepad_rstick_down")
local h_gamepad_rstick_digital_down = hash("gamepad_rstick_digital_down")
local h_gamepad_rstick_left = hash("gamepad_rstick_left")
local h_gamepad_rstick_digital_left = hash("gamepad_rstick_digital_left")
local h_gamepad_rstick_right = hash("gamepad_rstick_right")
local h_gamepad_rstick_digital_right = hash("gamepad_rstick_digital_right")

local abs = math.abs

local input_map = {
  [h_gamepad_lstick_right] = { stick = 1, x = 1, action_id = h_gamepad_lstick_digital_right },
  [h_gamepad_lstick_left] = { stick = 1, x = -1, action_id = h_gamepad_lstick_digital_left },
  [h_gamepad_lstick_up] = { stick = 1, y = 1, action_id = h_gamepad_lstick_digital_up },
  [h_gamepad_lstick_down] = { stick = 1, y = -1, action_id = h_gamepad_lstick_digital_down },
  [h_gamepad_rstick_right] = { stick = 2, x = 1, action_id = h_gamepad_rstick_digital_right },
  [h_gamepad_rstick_left] = { stick = 2, x = -1, action_id = h_gamepad_rstick_digital_left },
  [h_gamepad_rstick_up] = { stick = 2, y = 1, action_id = h_gamepad_rstick_digital_up },
  [h_gamepad_rstick_down] = { stick = 2, y = -1, action_id = h_gamepad_rstick_digital_down },
}

local deadzone = 0.5

local stick_count = 2
local stick_directions = {{
  right = h_gamepad_lstick_digital_right,
  left = h_gamepad_lstick_digital_left,
  up = h_gamepad_lstick_digital_up,
  down = h_gamepad_lstick_digital_down,
}, {
  right = h_gamepad_rstick_digital_right,
  left = h_gamepad_rstick_digital_left,
  up = h_gamepad_rstick_digital_up,
  down = h_gamepad_rstick_digital_down,
}}

local gamepads = {}

local function value_to_action_id(directions, x, y)
  local abs_x = abs(x)
  local abs_y = abs(y)
  if abs_x < deadzone and abs_y < deadzone then
    return nil
  end

  if x > 0 and abs_x > abs_y then
    return directions.right
  end

  if x < 0 and abs_x > abs_y then
    return directions.left
  end

  if y > 0 and abs_y > abs_x then
    return directions.up
  end

  if y < 0 and abs_y > abs_x then
    return directions.down
  end
end

local repeat_delay = tonumber(sys.get_config("input.repeat_delay", "0.5"))
local repeat_interval = tonumber(sys.get_config("input.repeat_interval", "0.2"))

local function make_stick(stick_index, gamepad)
  local last_action_id
  local digital_action_id
  local pending_x, pending_y
  local action_id_1, action_1, action_id_2, action_2
  local last_timestamp = 0
  local did_repeat = false

  local directions = stick_directions[stick_index]

  local pressed_action = {
    value = 1,
    pressed = true,
    released = false,
    repeated = false,
    gamepad = gamepad,
  }

  local released_action = {
    value = 0,
    pressed = false,
    released = true,
    repeated = false,
    gamepad = gamepad,
  }

  local repeated_action = {
    value = 1,
    pressed = false,
    released = false,
    repeated = true,
    gamepad = gamepad,
  }

  local continued_action = {
    value = 1,
    pressed = false,
    released = false,
    repeated = false,
    gamepad = gamepad,
  }

  local function set_value(new_action_id, x, y)
    pending_x = pending_x or x
    pending_y = pending_y or y

    if not pending_x or not pending_y then
      return
    end

    local new_digital_action_id = value_to_action_id(directions, pending_x, pending_y)

    if digital_action_id == new_digital_action_id then
      action_id_1 = digital_action_id
      action_1 = nil
      action_id_2 = nil
      action_2 = nil
      if digital_action_id then
        local timestamp = socket.gettime()
        if (timestamp - last_timestamp) >= (did_repeat and repeat_interval or repeat_delay) then
          action_1 = repeated_action
          last_timestamp = timestamp
          did_repeat = true
        else
          action_1 = continued_action
        end
      end
    else
      action_id_1 = digital_action_id
      action_1 = digital_action_id and released_action
      action_id_2 = new_digital_action_id
      action_2 = new_digital_action_id and pressed_action
      last_timestamp = socket.gettime()
      did_repeat = false
    end

    last_action_id = new_action_id
    digital_action_id = new_digital_action_id
    pending_x = nil
    pending_y = nil
  end

  local function convert_action(instance, action_id, action, callback)
    local consume = callback(instance, action_id, action)

    if action_id == last_action_id then
      if action_id_1 then
        consume = callback(instance, action_id_1, action_1) or consume
      end
      if action_id_2 then
        consume = callback(instance, action_id_2, action_2) or consume
      end
    end

    return consume or false
  end

  return { set_value = set_value, convert_action = convert_action }
end

local function get_gamepad(gamepad_index)
  local gamepad = gamepads[gamepad_index]
  if not gamepad then
    for i = #gamepads, gamepad_index do
      gamepad = {}
      for j = 1, stick_count do
        gamepad[j] = make_stick(j, gamepad_index)
      end
      gamepads[i] = gamepad
    end
  end
  return gamepad
end

local M = {}

function M.set_input_map(new_input_map)
  input_map = new_input_map
  gamepads = {}
  stick_count = 0
  for k, def in pairs(input_map) do
    if def.stick > stick_count then
      stick_count = def.stick
    end
  end

  stick_directions = {}
  for i = 1, stick_count do
    stick_directions[i] = {}
  end

  for k, def in pairs(input_map) do
    if def.x == 1 then stick_directions[def.stick].right = def.action_id
    elseif def.x == -1 then stick_directions[def.stick].left = def.action_id
    elseif def.y == 1 then stick_directions[def.stick].up = def.action_id
    elseif def.y == -1 then stick_directions[def.stick].down = def.action_id
    end
  end
end

function M.on_input(action_id, action)
  local def = input_map[action_id]
  if not def then return end

  local stick = get_gamepad(action.gamepad)[def.stick]
  local x, y = def.x, def.y
  if x then x = x * action.value end
  if y then y = y * action.value end

  stick.set_value(action_id, x, y)
end

local function convert_action(instance, action_id, action, callback)
  local def = input_map[action_id]
  if not def then return callback(instance, action_id, action) end

  local stick = get_gamepad(action.gamepad)[def.stick]
  return stick.convert_action(instance, action_id, action, callback)
end
M.convert_action = convert_action

function M.wrap_on_input(callback)
  return function (instance, action_id, action)
    return convert_action(instance, action_id, action, callback)
  end
end

return M
