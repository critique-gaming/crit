local EventEmitter = { __index = {} }

function EventEmitter.new()
  local self = {}
  setmetatable(self, EventEmitter)

  self.index = 1
  self.subscribers = {}
  return self
end

function EventEmitter.__index:subscribe(handler, ...)
  local index = self.index
  self.subscribers[index] = {
    handler = handler,
    arg = { n=select("#", ...), ... }
  }
  self.index = index + 1
  return index
end

function EventEmitter.__index:unsubscribe(index)
  self.subscribers[index] = nil
end

function EventEmitter.__index:dispatch(...)
  for i, sub in pairs(self.subscribers) do
    local handler = sub.handler
    local arg = sub.arg
    local n = arg.n

    if n == 0 then
      handler(...)
    elseif n == 1 then
      handler(arg[1], ...)
    elseif n == 2 then
      handler(arg[1], arg[2], ...)
    else
      local args = {}
      for j = 1, n do
        args[j] = arg[j]
      end
      for j = 1, select("#", ...) do
        args[j + n] = select(j, ...)
      end
      handler(unpack(args))
    end
  end
end

return EventEmitter
