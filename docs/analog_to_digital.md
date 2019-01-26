# Analog to digital thumb stick conversion

```lua
local analog_to_digital = require "crit.analog_to_digital"
```

Often times, you want the player to be able to navigate menus with the
left thumb stick just as they would with a D-pad. Unfortunately, the continuous
analog input actions that Defold fires cannot be treated as directional button
presses directly, even if you configure a dead-zone.

This module wraps your `on_input` function and emits additional digital
input actions corresponding to the thumb sticks.

## Setup

For this to work, `analog_to_digital.on_input(action, action_id)` must be called
in a game object's `on_input` at the very top of your input stack, which makes
sure that the module is aware of all gamepad input before it propagates down to
all other game objects.

If you use collection proxies to load your scenes, a common way to make sure
a game object is always at the top of the input stack is to make it acquire
input focus after the game object containing the collection proxy
acquires input focus.

## Usage

In the game objects where you need digital input,
wrap the `on_input` function with `analog_to_digital.wrap_on_input`,
as such:

```lua
on_input = analog_to_digital.wrap_on_input(function (self, action_id, action)
  if action_id == hash("gamepad_lstick_digital_down") and action.pressed then
    print("Gamepad left stick down pressed")
  end
end)
```

**This is not necessary for [Buttons](./button.lua). They use `analog_to_digital` automatically.**

## API

### `analog_to_digital.on_input(action_id, action)`

Call this as early as possible in the input stack to
keep track of the thumb sticks.

**Arguments:**  
* `action_id`: `hash`. The action ID to process
* `action`: `table`. The action object to process

### `analog_to_digital.wrap_on_input(on_input)`

Takes an `on_input` function and returns a new one that also gets called for
synthetic digital actions.

**Arguments:**  
* `on_input`: `function (instance, action_id, action)`. Original input handler
action.

**Return value:**

Returns a `wrapped_on_input(instance, action_id, action)` function that, when
called with an action, will call the original `on_input` at least once for the
original action, and then once more for each emitted synthetic digital action.

### `analog_to_digital.convert_action(instance, action_id, action, callback)`

Calls `callback(instance, action_id, action)`, then calls the `callback` again
with a synthetic digital action if one needs to be emitted based on the given
action.

**Arguments:**  
* `instance`: `*`. First argument passed to `callback`
* `action_id`: `hash`. The action ID to process
* `action`: `table`. The action object to process
* `callback`: `function (instance, action_id, action)`. Called to handle
the original action and the synthetic actions. Return `true` to handle the
action.

**Return value:**

Returns `true` if any of the `callback` calls returned `true`. Returns `false`
otherwise.

### `analog_to_digital.set_input_map(input_map)`

Configures the module to use a different input map. `input_map` is a table with
the following shape:

```lua
local input_map = { -- This is the default input map
  [hash("gamepad_lstick_right")] = { stick = 1, x = 1, action_id = hash("gamepad_lstick_digital_right") },
  [hash("gamepad_lstick_left")] = { stick = 1, x = -1, action_id = hash("gamepad_lstick_digital_left") },
  [hash("gamepad_lstick_up")] = { stick = 1, y = 1, action_id = hash("gamepad_lstick_digital_up") },
  [hash("gamepad_lstick_down")] = { stick = 1, y = -1, action_id = hash("gamepad_lstick_digital_down") },
  [hash("gamepad_rstick_right")] = { stick = 2, x = 1, action_id = hash("gamepad_rstick_digital_right") },
  [hash("gamepad_rstick_left")] = { stick = 2, x = -1, action_id = hash("gamepad_rstick_digital_left") },
  [hash("gamepad_rstick_up")] = { stick = 2, y = 1, action_id = hash("gamepad_rstick_digital_up") },
  [hash("gamepad_rstick_down")] = { stick = 2, y = -1, action_id = hash("gamepad_rstick_digital_down") },
}
```

Just in case you want to do some weird layouts, you are not limited to two sticks.
