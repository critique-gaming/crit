# The progression system

```lua
local progression = require "crit.progression"
```

The progression system can be thought of as the main way to establish the game's
high-level control flow.

Progressions are coroutines responsible with choreographing the different
elements of the game. They do things such as:  
  * determining the order of scenes
  * configuring scenes
  * managing character dialogue
  * controlling campaign progression logic

Progressions can be forked, joined and cancelled, just like real threads.

## Setup

1. Create a game object and add the `progression.script` script to it. All of
the progressions will be run in the context of this script.

2. Create a dyamycally-loaded factory on the same game object with the id `main`.
From it, spawn a game object with a script containing only the following code:

```
local progression = require "crit.progression"

local function main()
  print("This is the main progression: The entry-point of your progression system")
end

progression.init_register_function(main)
```

### Advanced usage

Theoretically, you can use this threading framework even without
`progression.script`, in whichever script you may need it. Just create coroutines
with `progression.detach()`. In this situation, the game-object-specific
functionality won't work (`progression.wait_for_message()` and dynamically
loading functions).

## Writing progressions

Each progression is a coroutine, meaning they're regular functions that
can occasionally **yield** their execution and wait for an external event to
happen before resuming.

Use helpers like `progression.wait_for_message()` to wait for messages sent
through the [Dispatcher](./dispatcher.md) or `progression.wait()` to wait a
certain amount of time.

Or, write your own helpers to wait for custom external events (see below).

## Forking, joining and cancelling

Forking creates a new coroutine running in parallel with the current one. There
are two ways to fork:
  * `progression.fork()`: Coroutines created like this will be automatically
  cancelled when their parent terminates (finishes running or is cancelled).
  * `progression.detach()`: Coroutines created like this will keep running in
  the background, regardless of what happens with their parent.

Joining with another coroutine means waiting until that coroutine terminated
(finished running or got cancelled). It's done with `progression.join()`.

You can always cancel the execution of a running coroutine with `progression.cancel()`.
This runs all the installed clean-up handlers on that coroutine and resumes all
the other coroutines waiting on it with `.join()`.

If you need to run something in the event that your coroutine gets cancelled,
you can install a clean-up handler with `progression.add_cleanup_handler()`.

## Writing custom yielding helper functions

The pattern is the following:  
1. Get a reference to the currently running coroutine:
`local co = coroutine.running()`
2. Make sure that when the external event happens,
`progression.resume(co)` is called in the context of `progression.script`.
3. Yield, optionally passing as a parameter a clean-up function called in
case the progression is cancelled. Make sure `resume` is not called
after the clean-up function is called.

Example:

```lua
local function wait_for_stuff()
  local co = coroutine.running()
  local listener_handle = add_stuff_listener(function ()
    remove_stuff_listener(listener_handle)
    progression.resume(co)
  end)
  coroutine.yield(co, function () -- Clean-up function
    remove_stuff_listener(listener_handle)
  end)
end
```

## Dynamically loading functions

Sometimes you may want to split your progression code in separate loadable
units, to speed up loading time. (There's no need to have the Lua interpreter
parse thousands of lines of scripted dialogue when all you need is to load the
main menu).

To do that, just like when setting up, create another factory on the progression
game object (choose an id for it). From it, just like before, spawn a script
with a single function being registered by `progression.init_register_function(f)`.

When you want to use that function somewhere in another progression, run
`progression.load_function(your_factory_id)` to load it, then call it as usual.

Or use `progression.lazy_load_function(your_factory_id)` to create a stand-in
function what will load the real function the first time it's called.

## Advanced usage

## API Documentation

### `progression.wait(seconds)`

This function yields until a number of seconds have passed.

**Arguments:**  
* `seconds`: `number`. The number of seconds to wait.

### `progression.wait_for_message(message_id, predicate)`

This function yields until a message with `message_id` is dispatched.

**Arguments:**  
* `message_id`: `hash | string`. The message id we're waiting for.
* `predicate`: `function (message_id, message)`. An optional function which
  can be used to filter unwanted messages. Returning `true` from this function
  will cause the message to be accepted and returned to the coroutine.
  Defaults to `function () return true end`.

**Return value:** `table`. The message body of the received message.

### `progression.fork(f, ...)`

Create a new coroutine and start it immediately. When the parent coroutine
terminates, this coroutine will be automatically cancelled.

**Arguments:**  
* `f`: `function`. The new coroutine's code to execute.
* `...`: Any extra arguments are passed to `f()`

**Return value:** `coroutine`. The newly created coroutine.

### `progression.create_fork(f)`

Create a new coroutine in a paused state. Call `progression.resume()` on it
to start it. When the parent coroutine terminates, this coroutine will be
automatically cancelled.

**Arguments:**  
* `f`: `function`. The new coroutine's code to execute.

**Return value:** `coroutine`. The newly created coroutine.

### `progression.detach(f, ...)`

Create a new coroutine and start it immediately. The coroutine is detached from
its parent and will keep running even if the parent terminates.

**Arguments:**  
* `f`: `function`. The new coroutine's code to execute.
* `...`: Any extra arguments are passed to `f()`

**Return value:** `coroutine`. The newly created coroutine.

### `progression.create_detached(f)`

Create a new coroutine in a paused state. Call `progression.resume()` on it
to start it. The coroutine is detached from its parent and will keep running
even if the parent terminates.

**Arguments:**  
* `f`: `function`. The new coroutine's code to execute.

**Return value:** `coroutine`. The newly created coroutine.

### `progression.cancel(co)`

Cancel a coroutine's execution. Calling this on already terminated coroutines is
a no-op.

**Arguments:**  
* `co`: `coroutine`. The coroutine to cancel.

### `progression.join(co)`

Wait for another coroutine to terminate. Calling this on already terminated
coroutines is a no-op.

**Arguments:**  
* `co`: `coroutine`. The coroutine to wait for.

### `progression.resume(co, ...)`

Resume the execution of a paused (yielded) coroutine.

**Arguments:**  
* `co`: `coroutine`. The coroutine to resume.
* `...`: Arguments to pass back to the coroutine (returned by `coroutine.yield()`)

### `progression.add_cleanup_handler(f, key, co)`

Install a cleanup handler that will run when the coroutine terminates
(finishes execution or is cancelled).

**Arguments:**  
* `f`: `function`. The cleanup handler function.
* `key`: *Optional.* An identifier to identify your handler. Defaults to `f` itself.
* `co`: `coroutine` *Optional.* The coroutine to install the handler for.
Defaults to the currently running coroutine.

**Return value:** The `key` identifier. Use it to remove the handler.

### `progression.remove_cleanup_handler(key, co)`

Un-install a cleanup handler.

**Arguments:**  
* `key`: The identifier returned by `progression.add_cleanup_handler()`.
* `co`: `coroutine` *Optional.* The coroutine to un-install the handler from.
Defaults to the currently running coroutine.

### `progression.load_function(factory_id)`

Asynchronously load a function from a factory.

**Arguments:**  
* `factory_id`: `hash | string`. The factory's id.

**Return value:** `function`: The loaded function.

### `progression.lazy_load_function(factory_id)`

Return a proxy function that, when first called, will asynchronously load a
function from a factory. After the load, it will forward all of its arguments
and return values to the newly loaded function.

**Arguments:**  
* `factory_id`: `hash | string`. The factory's id.

**Return value:** `function`: The proxy function. Call this just like you would
call the function to be loaded.

### `progression.register_function(f)`

Call this in a script's `init()` to register a dynamically loaded function.

**Arguments:**  
* `f`: `function`. The function to register

### `progression.init_register_function(f)`

Creates an `init()` function with a call to `progression.register_function(f)`.

**Arguments:**  
* `f`: `function`. The function to register
