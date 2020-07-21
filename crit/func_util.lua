local M = {}

function M.bind(f, self)
  return function (...)
    return f(self, ...)
  end
end

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
