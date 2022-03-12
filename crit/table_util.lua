--- Table manipulation utilities.
-- @module crit.table_util
-- @todo

local M = {}

M.unpack = unpack or table.unpack

local function deep_clone(t, transformer, iter)
  if transformer then
    t = transformer(t)
  end

  iter = iter or pairs

  if type(t) ~= "table" then
    return t
  end

  local new_t = {}
  for k, v in iter(t) do
    new_t[deep_clone(k, transformer, iter)] = deep_clone(v, transformer, iter)
  end
  return new_t
end

M.deep_clone = deep_clone

function M.rawpairs(t)
  return next, t, nil
end

function M.no_functions(v)
  if type(v) == "function" then
    return nil
  end
  return v
end

function M.clone(t)
  local new_t = {}
  for k, v in pairs(t) do
    new_t[k] = v
  end
  return new_t
end

local function deep_equal(a, b)
  if a == b then return true end
  if type(a) == "table" and type(b) == "table" then
    for k, v in pairs(a) do
      if not deep_equal(v, b[k]) then
        return false
      end
    end
    for k, v in pairs(b) do
      if v ~= nil and a[k] == nil then
        return false
      end
    end
    return true
  end
  return false
end
M.deep_equal = deep_equal

local function assign(target, source)
  if source then
    for k, v in pairs(source) do
      target[k] = v
    end
  end
  return target
end
M.assign = assign

function M.assign_all(target, ...)
  local n = select("#", ...)
  for i = 1, n do
    assign(target, select(i, ...))
  end
  return target
end

function M.map(t, mapper)
  local new_t = {}
  for k, v in pairs(t) do
    new_t[k] = mapper(v, k, t)
  end
  return new_t
end

function M.imap(t, mapper)
  local new_t = {}
  for k, v in ipairs(t) do
    new_t[k] = mapper(v, k, t)
  end
  return new_t
end

function M.reduce(t, reducer, initial_value)
  local i = 1
  if initial_value == nil then
    i = 2
    initial_value = t[1]
  end

  while true do
    local next_value = t[i]
    if next_value == nil then break end
    initial_value = reducer(initial_value, next_value, i, t)
    i = i + 1
  end
  return initial_value
end

function M.filter(t, predicate)
  local new_t = {}
  local i = 1
  for k, v in ipairs(t) do
    if predicate(v, k, t) then
      new_t[i] = v
      i = i + 1
    end
  end
  return new_t
end

function M.filter_in_place(t, predicate)
  local n = #t
  local i, j = 1, 1
  while j <= n do
    local v = t[j]
    if predicate(v, j, t) then
      if i ~= j then
        t[j] = nil
        t[i] = v
      end
      i = i + 1
    else
      t[j] = nil
    end
    j = j + 1
  end
  return t
end

local random = math.random

-- Fisher-Yates shuffle in-place
function M.shuffle(t, start_index, end_index)
  start_index = start_index or 1
  end_index = end_index or #t
  local start_index_0 = start_index - 1
  for i = end_index, start_index, -1 do
    local j = random(i - start_index_0) + start_index_0
    t[i], t[j] = t[j], t[i]
  end
  return t
end

-- Fisher-Yates shuffle
function M.shuffled(source)
  local result = {}
  local n = #source
  for i = 1, n do
    local j = random(i)
    result[i] = result[j]
    result[j] = source[i]
  end
  return result
end

function M.find(t, predicate)
  local n = #t
  for key = 1, n do
    local value = t[key]
    if predicate(value, key, t) then
      return value, key
    end
  end
  return nil
end

function M.includes(t, item)
  local n = #t
  for key = 1, n do
    local value = t[key]
    if value == item then
      return true
    end
  end
  return false
end

function M.remove_item(t, item)
  local n = #t
  for i = 1, n do
    if t[i] == item then
      table.remove(t, i)
      break
    end
  end
end

function M.concat(tables)
  local t = {}
  for i = 1, #tables do
    M.append_all(t, tables[i])
  end
  return t
end

function M.append_all(t, source)
  local n = #t
  for i = 1, #source do
    t[i + n] = source[i]
  end
  return t
end

local dump
local function format_key(x)
  if type(x) == "string" and string.match(x, "^[_a-zA-Z][_0-9a-zA-Z]*$") then
    return x
  end
  return "[" .. dump(x) .. "]"
end

function dump(x, identation)
  identation = identation or ""
  local tp = type(x)
  if tp == "table" then
    local ident = identation .. "  "
    local s = "{"
    local n = #x
    for i = 1, n do
      s = s .. "\n" .. ident .. dump(x[i], ident) .. ","
    end
    for k, v in pairs(x) do
      if type(k) ~= "number" or k < 1 or k > n then
        s = s .. "\n" .. ident .. format_key(k) .. " = " .. dump(v, ident) .. ","
      end
    end
    if s == "{" then
      s = "{}"
    else
      s = s .. "\n" .. identation .. "}"
    end
    return s
  elseif tp == "string" then
    return string.format("%q", x)
  else
    return tostring(x)
  end
end
M.dump = dump

function M.index_of(t, value)
  for i = 1, #t do
    if t[i] == value then
      return i
    end
  end
  return nil
end

return M
