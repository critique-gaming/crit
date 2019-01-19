# The progression system

> TODO: Update and revamp

The progression system can be thought of as the main way to establish the game's
high-level control flow.

Progressions are coroutines responsible with choreographing the different
elements of the game. They do things such as:  
  * determining the order of scenes
  * configuring scenes
  * managing character dialogue
  * controlling campaign progression logic

## Running a progression

There can be only one progression running at one time. Starting a new
progression will cancel the previous one.

Each progression is identified by a string id. See
[main/progression/entry.lua](../main/progression/entry.lua) for a list of
available progressions.

At start-up, the `main` progression will be started, which loads the main
menu. This behaviour can be overriden in [env.lua](./the-env-file.md) with
`env.entry_progression`.

Whenever you need to change the progression, dispatch the following message:

```lua
dispatcher.dispatch("run_progression", {
  id = "progression_id"
  options = 42, -- Optional argument passed as the first argument to the progression coroutine
})
```

## Writing progressions

All progressions must be defined in the `progressions` table in
[main/progression/entry.lua](../main/progression/entry.lua).

Each progression is a coroutine, meaning they're regular functions that
can occasionally **yield** their execution and wait for an external event to
happen before resuming.

APIs for use within progressions can be accessed with:
```lua
local progression = require "crit.progression"
```

### `progression.wait(seconds)`

This function yields until a number of seconds have passed.

**Arguments:**  
* `seconds`: `number`. The number of seconds to wait.

### `progression.wait_for_message(message_id, predicate)`

This function yields until a message with `message_id` is dispatched. `message_id` must be a hash.

**Arguments:**  
* `message_id`: `hash | string`. The message id we're waiting for.
* `predicate`: `function (message_id, message)`. An optional function which
  can be used to filter unwanted messages. Returning `true` from this function
  will cause the message to be accepted and returned to the coroutine.
  Defaults to `function () return true end`.

**Return value:** `table`. The message body of the received message.

### `scenes.load_scene(scene, options, transition)`

Start a transition to a new scene. This function yields until the new scene
has been loaded and initialised.

**Arguments:**  
* `scene`: `string`. The id of the scene to transition to.
* `options`: `table`. Options to pass to the scene. Optional. Defaults to `{}`.
* `transition`: `string | false`. The transition effect to use for switching
  scenes. Optional. Defaults to `"fade"`. Supported transitions:  
  * `"fade"`: Fade screen to black
  * `false`: No transition. Immediately swap scenes


### `scenes.wait_for_end_scene()`

This function yields until the `end_scene` message is dispatched and
returns the message body.

**Return value:** `table`. The message body of the `end_scene` message.

## Writing custom yielding helper functions

The pattern is the following:  
1. Get a reference to the currently running coroutine:
`local co = coroutine.running()`
2. Make sure that when the external event happens,
`progression.resume_coroutine(co)` is called in the context of the `main:/scene#progression` game object script.
3. Yield, optionally passing as a parameter a clean-up function called in
case the progression is cancelled. Make sure `resume_coroutine` is not called
after the clean-up function is called.

Example:

```lua
local function wait_for_stuff()
  local co = coroutine.running()
  local listener = add_stuff_listener(function ()
    progression.resume_coroutine(co)
  end)
  coroutine.yield(co, function ()
    remove_stuff_listener(listener)
  end)
end
```
