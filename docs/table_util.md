# Table manipulation utilities

```lua
local table_util = require "crit.table_util"
```

Module containing various useful table manipulation functions.

## API

### `table_util.shuffle(t)`

Shuffles table `t` in-place.

**Arguments:** `t`: `table`. A table with integer keys.

### `table_util.shuffled(t)`

Returns a shuffled copy of table `t`.

**Arguments:** `t`: `table`. A table with integer keys.

### `table_util.clone(t)`

Returns a shallow clone of table `t`.

### `table_util.deep_clone(t, transformer)`

Returns a recursive clone of table `t`.

**Don't use this on tables with circular references.**

**Arguments:**
  * `t`: `table`. The table to clone.
  * `transformer`: `function (value)`. *Optional*. All values encountered during
  recursive transversal of the table (table keys, values, even the table itself)
  pass through this function. Use it, for example, to sanitise a table before
  serialisation.

### `table_util.no_functions(value)`

Returns `nil` if `value` is a function. Otherwise, returns `value`. Useful
as a `transformer` in `table_util.deep_clone()` to filter out all functions.

### `table_util.assign(target, source)`

Copies all key-value pairs from the `source` table to the `target` table.

### `table_util.map(t, mapper)`

Returns a copy of `t`, where all keys are passed through a `mapper` function.

**Arguments:**
  * `t`: `table`. The source table.
  * `mapper`: `function (value, key, t)`. Called for each key-value pair in `t`.
  Its return value determines the new value associated with `key` in the
  returned table.

### `table_util.imap(t, mapper)`

Same as `table_util.map(t, mapper)`, but only operates on tables with integer
keys, calling the `mapper` in the order of the keys.

### `table.reduce(t, reducer, initial_value)`

The `reduce()` function executes a `reducer` function on each element in the  
integer-indexed table `t`, resulting in a single output value.

**Arguments:**
  * `t`: `table`. The integer-indexed table to iterate on.
  * `initial_value`: `*`. The initial value of the accumulator. If not provided
  or `nil`, the first element of the table will be used instead and the
  `reducer` will only be called starting with the second element.
  * `reducer`: `function (accumulator, value, key, t)`. The reducer function
  should calculate and return the next value of the accumulator based on the
  previous `accumulator` and the current `value`.

**Return value:**

Returns the final returned value of the accumulator from the `reducer` function.

### `table_util.filter(t, predicate)`

Calls `predicate()` on each element of integer-indexed table `t` to determine
if the element is to be kept. Returns a new table with the filtered elements
removed.

**Arguments:**
  * `t`: `table`. The integer-indexed table to filter.
  * `predicate`: `function (value, key, t)`. Return `false` or `nil` to remove
  the current element.

### `table_util.filter_in_place(t, predicate)`

Calls `predicate()` on each element of integer-indexed table `t` to determine
if the element is to be kept. Removes the filtered elements in-place from the 
given table.

**Arguments:**
  * `t`: `table`. The integer-indexed table to filter.
  * `predicate`: `function (value, key, t)`. Return `false` or `nil` to remove
  the current element.

### `table_util.deep_equal(a, b)`

Returns `true` if the two values are equal. If they are tables, they are checked 
for deep equality key by key.

**Don't use this on tables with circular references.**

**Arguments:**
  * `a`: `any`. First item to compare.
  * `b`: `any`. Second item to compare.
