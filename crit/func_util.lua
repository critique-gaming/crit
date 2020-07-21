--- Utilities for working with functions.
-- @module crit.func_util

local M = {}

--- Bind a first parameter to a function.
-- Returns a wrapped function with `arg` bound to the first parameter.
-- Call it with the remaining parameters.
-- @tparam function f The function to wrap.
-- @tparam any arg The argument to bind as first argument.
-- @treturn function The wrapped function.
function M.bind(f, arg)
  return function (...)
    return f(arg, ...)
  end
end

--- Compose multiple functions.
-- Returns a function that chains the provided list of functions. For example,
-- `func_util.compose(f, g, h)(x)` is the equivalent of `f(g(h(x)))`.
-- @tparam function ... A list of functions to compose. If empty, returns the identity function.
-- @treturn function The composed function.
function M.compose(...)
  local funcs = {...}
  local n = #funcs

  local function recurse(i, ...)
    if i == 0 then
      return ...
    end
    return recurse(i - 1, funcs[i](...))
  end

  return function (...)
    return recurse(n, ...)
  end
end

return M
