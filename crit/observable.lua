--- Observables.
-- @module crit.observable
-- @todo

local M = {}

function M.subject()
  local subscriptions = {}
  local subscriptions_to_add
  local iterating = false

  local function emit(...)
    iterating = true
    for f in pairs(subscriptions) do
      f(...)
    end
    iterating = false

    if subscriptions_to_add then
      for f in pairs(subscriptions_to_add) do
        subscriptions[f] = true
      end
      subscriptions_to_add = nil
    end
  end

  local function subscribe(f)
    if iterating then
      subscriptions_to_add = subscriptions_to_add or {}
      subscriptions_to_add[f] = true
    else
      subscriptions[f] = true
    end

    return function ()
      if subscriptions_to_add then
        subscriptions_to_add[f] = nil
      end
      subscriptions[f] = nil
    end
  end

  return emit, subscribe
end

--- Unsubscribe from multiple subscriptions in one go.
-- Creates `collect` and `dispose` functions. First, call `collect(f)` on all
-- unsubscribe functions that you want to add to the disposer. Then, when you
-- want to unsubscribe, call `dispose()` and all the collected functions will
-- be called.
-- @return[type=function (unsub: function)] `collect` function. Collects `unsub` functions.
-- @return[type=function ()] `dispose` function. Calls all `collect`ed function.
function M.disposer()
  local disposables

  local function collect(disposable)
    if not disposables then
      disposables = {}
    end
    disposables[#disposables + 1] = disposable
  end

  local function dispose()
    if disposables then
      for i = 1, #disposables do
        disposables[i]()
      end
    end
    disposables = nil
  end

  return collect, dispose
end

function M.observe(f)
  local collect, dispose

  local function on_change()
    if dispose then dispose() end
    collect, dispose = M.disposer()

    local function add_sub(subscribe)
      collect(subscribe(on_change))
    end

    f(add_sub, dispose)
  end

  on_change()

  return function ()
    dispose()
  end
end

function M.observe_table(make_iterator, subscribe, f)
  local dispose

  if type(make_iterator) == "table" then
    local t = make_iterator
    make_iterator = function () return pairs(t) end
  end

  assert(type(make_iterator) == "function", "make_iterator needs to be a table or a function that returns an iterator")

  local subs = {}
  local tick = false
  local function on_change()
    tick = not tick

    -- Subscribe to the new items
    for key, value in make_iterator() do
      local sub = subs[key]
      if not sub then
        subs[key] = { unsub = f(key, value), tick = tick }
      else
        sub.tick = tick
      end
    end

    -- Unsubscribe from the deleted items
    for key, sub in pairs(subs) do
      if sub.tick ~= tick then
        subs[key] = nil
        local sub_dispose = sub.dispose
        if sub_dispose then
          sub_dispose()
        end
      end
    end
  end

  dispose = subscribe(on_change)
  on_change()

  return function ()
    if dispose then dispose() end
    for _, sub in pairs(subs) do
      local sub_dispose = sub.dispose
      if sub_dispose then
        sub_dispose()
      end
    end
  end
end


function M.wait_and_observe(f)
  local co = coroutine.running()
  local is_done = false
  local returned_data
  local unsub = M.observe(function (add_sub, dispose)
    local function done(data)
      dispose()
      if not is_done then
        is_done = true
        returned_data = data
        if coroutine.running() ~= co then
          coroutine.resume(co)
        end
      end
    end
    f(done, add_sub, dispose)
  end)
  if not is_done then
    coroutine.yield(unsub)
  end
  return returned_data
end

return M
