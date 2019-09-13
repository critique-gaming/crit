# Sprite picking

```lua
local pick = require "crit.pick"
```

One-function module that tells you if a point falls inside of a sprite or not.

## API

### `pick.pick_sprite(sprite_url, x, y, padding)`

Picks a sprite.

**Limitations:**
  * The sprite must be positioned at the origin of its parent game object
  * The sprite must not be rotated inside of its parent game object
  * The sprite must not be scaled inside of its parent game object

**Arguments:**
  * `sprite_url`: `url | string`. An URL identifying the sprite component.
  * `x`, `y`: `number`. The point (in world space) to do the check on.
  * `padding`: `table`. *Optional.* By how much should the hitbox of the sprite
  be expanded or constricted.
    * `top`, `bottom`, `left`, `right`: `number`. Padding values. Can also be negative.

**Return value:**

Returns `true` if the point hits inside the sprite and `false` otherwise.
