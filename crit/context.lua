--- Switch between script contexts.
-- @module crit.context
-- @todo

local h_context_switch = hash("context_switch")

local M = {}

local funcs = {}

--- Schedule a function to run in the context of another script.
--
-- For this to work, the script being targeted must call `handle()` in its `on_message()`.
-- @param[type=url|hash|string] msg_id URL to the script in which to run the function.
-- @param[type=function] f The function to run in another context.
-- @function run_as
local function run_as(msg_id, f)
  local id = #funcs + 1
  funcs[id] = f
  msg.post(msg_id, h_context_switch, { id = id })
end
M.run_as = run_as

--- Wrap a function so that it runs in another script's context.
--
-- For this to work, the script being targeted must call `handle()` in its `on_message()`.
-- @param[type=url|hash|string] msg_id URL to the script in which to run the function.
-- @param[type=function] f The function to run in another context.
-- @treturn function The wrapped function. When called, it will schedule `f` to
--   run in the target script's context. Arguments are passed through to `f`, but
--   any return values are lost (since `run_as()` doesn't actually call the function
--   synchroneously).
function M.as(msg_id, f)
  local target_url = msg.url(msg_id)
  return function (...)
    local args = {...}
    run_as(target_url, function ()
      f(unpack(args))
    end)
  end
end

--- Handle incoming `run_as()` requests.
--
-- For this module to work, you need to call this in `on_message()` in any
-- script that might be targeted by `run_as()`.
-- @param[type=hash] message_id
-- @param[type=table] message_id
function M.handle(message_id, message)
  if message_id == h_context_switch then
    local id = message.id
    local f = funcs[id]
    funcs[id] = nil
    if f then f() end
  end
end

return M
