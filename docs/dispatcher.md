# Dispatching messages

Defold has a message passing architecture. Scripts communicate to other
scripts and engine facilities by sending messages to each other:

**Sender:**

```lua
msg.post("#some-other-script", "some_message_id", { foo = "bar" })
```

**Receiver:**

```lua
function on_message(self, message_id, message)
  if message_id == hash("some_message_id") then
    print("Received message with data: " .. message.foo)
  end
end
```

The problem with this architecture is that in order to send a message,
each script must explicitly reference the receiver of the message, thus
creating a dependency on the receiving script.

Our solution to this problem is to have a singleton **dispatcher** object which
receives messages from all scripts and routes them to the scripts that explicitly
subscribe to each type of message (message id).

This way, the receiver doesn't need to be known in advance and is decoupled from
the sender.

**Sender:**

```lua
local dispatcher = require "crit.dispatcher"
dispatcher.dispatch("some_message_id", { foo = "bar" })
```

**Receiver:**

```lua
local dispatcher = require "crit.dispatcher"

function init(self)
  self.sub_id = dispatcher.subscribe({ hash("some_message_id") })
end

function final(self)
  dispatcher.unsubscribe(self.sub_id)
end

function on_message(self, message_id, message)
  if message_id == hash("some_message_id") then
    print("Received message with data: " .. message.foo)
  end
end
```

## Dispatcher API reference

### `dispatcher.dispatch(message_id, message)`

Dispatches a message to subscribers.

**Arguments:**  
* `message_id`: `hash | string`. The message id.
* `message`: `table`. The message body. Optional. Defaults to `{}`.

### `dispatcher.subscribe(messages)`

Subscribes the current script to the dispatcher, enabling it to receive the
listed messages in its own `on_message`.

**Arguments:**  
* `messages`: `table of hashes`. A list of message id hashes to subscribe to.

**Return value:** `number`. An id identifying the subscription. Used for unsubscribing.

### `dispatcher.subscribe_hook(messages, on_message)`

Adds a hook function that will be called for each message from the list, before
it gets dispatched.

**Arguments:**  
* `messages`: `table of hashes`. A list of message id hashes to subscribe to.
* `on_message`: `function (message_id, message)`. The hook function.

**Return value:** `number`. An id identifying the subscription. Used for unsubscribing.

### `dispatcher.unsubscribe(subscription_id)`

Invalidates a dispatcher subscription created with `subscribe()` or
`subscribe_hook()`.

Forgetting to call this in `final()` results in messages being dispatched to a
deleted game object, which is an error.

**Arguments:**  
* `subscription_id`: `number`. The id of the subscription returned from `subscribe()` or `subscribe_hook()`.
