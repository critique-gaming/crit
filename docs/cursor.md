# Mouse cursor hiding manager

```lua
local cursor = require "crit.cursor"
```

Simple module helping you manage cursor visibility. This module works with multiple
priority tiers. You can set or unset the cursor to be hidden/explicitly shown
for each priority and the highest priority setting will always be used.

Example use case with 3 priority tiers: The game generally shows the cursor,
except that in this particular scene (a cutscene) the cursor is hidden,
except that now the player paused the game, so the cursor is explicitly shown.

This module requires [DefOS](https://github.com/subsoap/defos), but won't break
if you don't have it added to your dependencies or on platforms that DefOS doesn't
support.

## API

### `cursor.set_visible(visible, priority)`

Set the cursor as explicitly visible/hidden for a given priority or unset the
setting for a given priority.

**Arguments:**  
* `visible`: `boolean | nil`. Pass `true` to explicitly show the cursor, `false`
  to hide it and `nil` to unset the setting for this priority tier and allow
  lower priority settings to be used.
* `priority`: `number`. The priority of this setting.

### `cursor.get_visible()`

Check if the cursor is visible or not. The setting with the highest priority
will be returned.

**Return value:**

Returns `true` if the cursor is shown and `false` if it's hidden.

### Pre-defined priorities

Some handy pre-defined priority levels to use with `cursor.set_visible()`:

```lua
cursor.PRIORITY_DEFAULT = 0
cursor.PRIORITY_INPUT_METHOD = 1
cursor.PRIORITY_SCENE_LOW = 9
cursor.PRIORITY_SCENE = 10
cursor.PRIORITY_SCENE_HIGH = 11
cursor.PRIORITY_PAUSE_MENU = 20
cursor.PRIORITY_IMPORTANT = 30
```
