--- Switch between script contexts.
-- @module crit.context
-- @todo

local h_context_switch = hash("context_switch")

local M = {}

local funcs = {}

local function run_as(msg_id, f)
  local id = #funcs + 1
  funcs[id] = f
  msg.post(msg_id, h_context_switch, { id = id })
end
M.run_as = run_as

function M.as(msg_id, f)
  return function ()
    run_as(msg_id, f)
  end
end

function M.handle(message_id, message)
  if message_id == h_context_switch then
    local id = message.id
    local f = funcs[id]
    funcs[id] = nil
    if f then f() end
  end
end

return M
