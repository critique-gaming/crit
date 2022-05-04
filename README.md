# Crit - Building blocks for Defold games

A battle-tested collection of un-opinionated modules we use at 
[Critique Gaming](https://critique-gaming.com)
to make games with [Defold](https://defold.com).

The modules are self-contained and depend on each other as little as possible,
each designed to solve one specific problem. Use as much or as little as you need.

**Links:**

* [GitHub repo](https://github.com/critique-gaming/crit)
* [Documentation](https://critique-gaming.github.io/crit)
* [Starter project](https://github.com/critique-gaming/crit-boilerplate)

## Modules

* UI
  * [Buttons](https://critique-gaming.github.io/crit/modules/crit.button.html)
  * [Tooltips](https://critique-gaming.github.io/crit/modules/crit.tooltip.html)
  * [Responsive layout](https://critique-gaming.github.io/crit/modules/crit.layout.html)
  * [Drag and drop](https://critique-gaming.github.io/crit/modules/crit.drag_and_drop.html)
  * [Scroll views](https://critique-gaming.github.io/crit/modules/crit.scroll.html)
  * [Scroll bars](https://critique-gaming.github.io/crit/modules/crit.scrollbar.html)
  * [Sprite picking](https://critique-gaming.github.io/crit/modules/crit.pick.html)
  * [Panning inertia](https://critique-gaming.github.io/crit/modules/crit.inertia.html)
* Architecture
  * [The message dispatcher](./docs/dispatcher.md)
  * [Coroutine progression system](./docs/progression.md)
  * [Observables](https://critique-gaming.github.io/crit/modules/crit.observable.html)
* Input
  * [Keyboard/gamepad focus](https://critique-gaming.github.io/crit/modules/crit.focus_giver.html)
  * [Keyboard/gamepad focus state](https://critique-gaming.github.io/crit/modules/crit.input_state.html)
  * [Analog to digital thumb stick conversion](./docs/analog_to_digital.md)
  * [Mouse cursor hiding manager](./docs/cursor.md)
  * [Screen corner hotspots](https://critique-gaming.github.io/crit/modules/crit.hotspots.html)
  * [Cheatcodes](https://critique-gaming.github.io/crit/modules/crit.cheatcodes.html)
* [Internationalisation](./docs/intl.md)
* Utilities
  * [Color manipulation utilities](https://critique-gaming.github.io/crit/modules/crit.colors.html)
  * [Table manipulation utilities](./docs/table_util.md)
  * [Function utilities](https://critique-gaming.github.io/crit/modules/crit.func_util.html)
  * [Low-pass and high-pass filters](https://critique-gaming.github.io/crit/modules/crit.filters.html)
  * [The environment file](./docs/env.md)
  * [System configuration constants](https://critique-gaming.github.io/crit/modules/crit.sys_config.html)
  * [Switch between script contexts](https://critique-gaming.github.io/crit/modules/crit.context.html)
* Editor scripts
  * [Layers from fonts](https://critique-gaming.github.io/crit/scripts/layers_from_fonts.editor_script.html)

## Examples

You can find usage examples in this repo. Alternatively, if you need a
ready-to-go starter project based on Crit and [Monarch](https://github.com/britzl/monarch),
check out [crit-boilerplate](https://github.com/critique-gaming/crit-boilerplate).

## Default input map

These modules make little assumptions about your environment, but come with a
few sensible defaults. You can configure each module to use different
action IDs for its input, but the default input map is the following:

|Input|Action ID|
|-|-|
|`MOUSE_BUTTON_1`|`touch`|
|`MOUSE_WHEEL_UP`|`wheel_up`|
|`MOUSE_WHEEL_DOWN`|`wheel_down`|
|`KEY_UP`|`key_up`|
|`KEY_DOWN`|`key_down`|
|`KEY_LEFT`|`key_left`|
|`KEY_RIGHT`|`key_right`|
|`KEY_ENTER`|`key_enter`|
|`KEY_SPACE`|`key_space`|
|`GAMEPAD_LPAD_LEFT`|`gamepad_lpad_left`|
|`GAMEPAD_LPAD_RIGHT`|`gamepad_lpad_right`|
|`GAMEPAD_LPAD_UP`|`gamepad_lpad_up`|
|`GAMEPAD_LPAD_DOWN`|`gamepad_lpad_down`|
|`GAMEPAD_RPAD_LEFT`|`gamepad_rpad_left`|
|`GAMEPAD_RPAD_RIGHT`|`gamepad_rpad_right`|
|`GAMEPAD_RPAD_UP`|`gamepad_rpad_up`|
|`GAMEPAD_RPAD_DOWN`|`gamepad_rpad_down`|
|`GAMEPAD_START`|`gamepad_start`|
|`GAMEPAD_BACK`|`gamepad_back`|
|`GAMEPAD_GUIDE`|`gamepad_guide`|
|`GAMEPAD_RSHOULDER`|`gamepad_rshoulder`|
|`GAMEPAD_LSHOULDER`|`gamepad_lshoulder`|
|`GAMEPAD_LTRIGGER`|`gamepad_ltrigger`|
|`GAMEPAD_RTRIGGER`|`gamepad_rtrigger`|
|`GAMEPAD_LSTICK_LEFT`|`gamepad_lstick_left`|
|`GAMEPAD_LSTICK_RIGHT`|`gamepad_lstick_right`|
|`GAMEPAD_LSTICK_UP`|`gamepad_lstick_up`|
|`GAMEPAD_LSTICK_DOWN`|`gamepad_lstick_down`|
|`GAMEPAD_RSTICK_LEFT`|`gamepad_rstick_left`|
|`GAMEPAD_RSTICK_RIGHT`|`gamepad_rstick_right`|
|`GAMEPAD_RSTICK_UP`|`gamepad_rstick_up`|
|`GAMEPAD_RSTICK_DOWN`|`gamepad_rstick_down`|
|`GAMEPAD_LSTICK_CLICK`|`gamepad_lstick_click`|
|`GAMEPAD_RSTICK_CLICK`|`gamepad_rstick_click`|

**[Synthetic digital thumbstick actions](./docs/analog_to_digital.md):**

|Input|Digital action ID|
|-|-|
|`GAMEPAD_LSTICK_LEFT`|`gamepad_lstick_digital_left`|
|`GAMEPAD_LSTICK_RIGHT`|`gamepad_lstick_digital_right`|
|`GAMEPAD_LSTICK_UP`|`gamepad_lstick_digital_up`|
|`GAMEPAD_LSTICK_DOWN`|`gamepad_lstick_digital_down`|
|`GAMEPAD_RSTICK_LEFT`|`gamepad_rstick_digital_left`|
|`GAMEPAD_RSTICK_RIGHT`|`gamepad_rstick_digital_right`|
|`GAMEPAD_RSTICK_UP`|`gamepad_rstick_digital_up`|
|`GAMEPAD_RSTICK_DOWN`|`gamepad_rstick_digital_down`|

