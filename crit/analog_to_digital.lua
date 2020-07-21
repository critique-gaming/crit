--- Analog to digital thumb stick conversion.
-- @module crit.analog_to_digital
-- @todo

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
local h_gamepad_ltrigger = hash("gamepad_ltrigger")
local h_gamepad_ltrigger_digital = hash("gamepad_ltrigger_digital")
local h_gamepad_rtrigger = hash("gamepad_rtrigger")
local h_gamepad_rtrigger_digital = hash("gamepad_rtrigger_digital")
local h_gamepad_disconnected = hash("gamepad_disconnected")

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
  [h_gamepad_ltrigger] = { stick = 3, x = 1, unidirectional = true, action_id = h_gamepad_ltrigger_digital },
  [h_gamepad_rtrigger] = { stick = 4, x = 1, unidirectional = true, action_id = h_gamepad_rtrigger_digital },
  [h_gamepad_disconnected] = { disconnected = true },
}

local deadzone = 0.5

local stick_count = 4
local stick_directions = {{
  right = h_gamepad_lstick_digital_right,
  left = h_gamepad_lstick_digital_left,
  up = h_gamepad_lstick_digital_up,
  down = h_gamepad_lstick_digital_down,
  bidirectional = true,
}, {
  right = h_gamepad_rstick_digital_right,
  left = h_gamepad_rstick_digital_left,
  up = h_gamepad_rstick_digital_up,
  down = h_gamepad_rstick_digital_down,
  bidirectional = true,
}, {
  right = h_gamepad_ltrigger_digital,
  bidirectional = false,
}, {
  right = h_gamepad_rtrigger_digital,
  bidirectional = false,
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
local convert_action_recursed = false

local function make_stick(stick_index, gamepad)
  local last_action_id
  local digital_action_id
  local pending_x, pending_y
  local last_x, last_y = 0.0, 0.0
  local action_id_1, action_1, action_id_2, action_2
  local last_timestamp = 0
  local did_repeat = false

  local directions = stick_directions[stick_index]
  local default_bidirectional = directions.bidirectional
  local bidirectional = default_bidirectional

  local pressed_action = {
    value = 1,
    pressed = true,
    released = false,
    repeated = true, -- To replicate Defold behaviour
    gamepad = gamepad,
    simulated = true,
  }

  local released_action = {
    value = 0,
    pressed = false,
    released = true,
    repeated = false,
    gamepad = gamepad,
    simulated = true,
  }

  local repeated_action = {
    value = 1,
    pressed = false,
    released = false,
    repeated = true,
    gamepad = gamepad,
    simulated = true,
  }

  local continued_action = {
    value = 1,
    pressed = false,
    released = false,
    repeated = false,
    gamepad = gamepad,
    simulated = true,
  }

  local function set_value(new_action_id, x, y)
    last_x = x or last_x
    last_y = y or last_y

    pending_x = x or pending_x
    pending_y = y or pending_y

    action_id_1 = nil
    action_1 = nil
    action_id_2 = nil
    action_2 = nil

    if bidirectional and (not pending_x or not pending_y) then
      return
    end

    local new_digital_action_id = value_to_action_id(directions, last_x, last_y)

    if digital_action_id == new_digital_action_id then
      if new_digital_action_id then
        local timestamp = socket.gettime()
        if (timestamp - last_timestamp) >= (did_repeat and repeat_interval or repeat_delay) then
          action_id_1 = new_digital_action_id
          action_1 = repeated_action
          last_timestamp = timestamp
          did_repeat = true
        else
          action_id_1 = new_digital_action_id
          action_1 = continued_action
        end
      end
    else
      if digital_action_id then
        action_id_1 = digital_action_id
        action_1 = released_action
      end
      if new_digital_action_id then
        action_id_2 = new_digital_action_id
        action_2 = pressed_action
      end
      last_timestamp = socket.gettime()
      did_repeat = false
    end

    last_action_id = new_action_id
    digital_action_id = new_digital_action_id
  end

  local function convert_action(instance, action_id, action, callback)
    local recursed = convert_action_recursed
    convert_action_recursed = true

    local consume = callback(instance, action_id, action)

    if not recursed and action_id == last_action_id then
      if action_id_1 then
        consume = callback(instance, action_id_1, action_1) or consume
      end
      if action_id_2 then
        consume = callback(instance, action_id_2, action_2) or consume
      end
    end

    convert_action_recursed = recursed
    return consume or false
  end

  local function reset(action_id)
    last_action_id = nil
    if action_id then
      if digital_action_id then
        set_value(action_id, 0, 0)
      end
    end
    digital_action_id = nil
    pending_x = nil
    pending_y = nil
    last_x = 0.0
    last_y = 0.0
    did_repeat = false
    bidirectional = default_bidirectional
  end

  local function update()
    if bidirectional then
      if (pending_x or pending_y) and not (pending_x and pending_y) then
        -- This stick is probably mapped to a HAT. Fall back to unidirectional
        bidirectional = false
      end
    else
      -- We got two axis in one frame. It's probably an analog stick. Back to bidirectional mode
      if pending_x and pending_y then
        bidirectional = true
      end
    end

    pending_x = nil
    pending_y = nil
  end

  return {
    set_value = set_value,
    convert_action = convert_action,
    reset = reset,
    update = update,
  }
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
    stick_directions[i] = { bidirectional = true }
  end

  for k, def in pairs(input_map) do
    if def.x == 1 then stick_directions[def.stick].right = def.action_id
    elseif def.x == -1 then stick_directions[def.stick].left = def.action_id
    elseif def.y == 1 then stick_directions[def.stick].up = def.action_id
    elseif def.y == -1 then stick_directions[def.stick].down = def.action_id
    end
    if def.unidirectional then
      stick_directions[def.stick].bidirectional = false
    end
  end
end

function M.on_input(action_id, action)
  local def = input_map[action_id]
  if not def then return end

  if def.disconnected then
    local gamepad = get_gamepad(action.gamepad)
    for _, stick in ipairs(gamepad) do
      stick.reset(action_id)
    end
    return
  end

  local stick = get_gamepad(action.gamepad)[def.stick]
  local x, y = def.x, def.y
  if x then x = x * action.value end
  if y then y = y * action.value end

  stick.set_value(action_id, x, y)
end

function M.update()
  for _, gamepad in pairs(gamepads) do
    for stick_index = 1, #gamepad do
      gamepad[stick_index].update()
    end
  end
end

local function convert_action(instance, action_id, action, callback)
  local def = input_map[action_id]
  if not def or not def.stick then
    return callback(instance, action_id, action)
  end

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
