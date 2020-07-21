--- The message dispatcher.
-- @module crit.dispatcher
-- @todo

local M = {}

local generated_id_count = 1
local events = {}
local subscribers = {}

local message_queue = {}
local message_queue_active = 0

local function generate_id()
  local id_count = generated_id_count
  generated_id_count = id_count + 1
  return id_count
end

local function dispatcher_subscribe(messages, hook_on_message)
  local id = generate_id()
  local url = msg.url()

  if subscribers[id] then
    print("WARNING: Subscriber " .. id .. " already registered. Overwriting subscription")
    M.unsubscribe(id)
  end

  local sub = {
    id = id,
    url = url,
    messages = messages,
    handler = hook_on_message,
  }
  subscribers[id] = sub

  for i, message_id in ipairs(messages) do
    local event = events[message_id]
    if not event then
      event = { hooks = {}, subs = {} }
      events[message_id] = event
    end

    if hook_on_message then
      event.hooks[id] = sub
    else
      event.subs[id] = sub
    end
  end

  return id
end

function M.subscribe(messages)
  return dispatcher_subscribe(messages)
end

function M.subscribe_hook(messages, on_message)
  if type(on_message) ~= "function" then
    error("Second argument to subscribe_hook must be an on_message function")
  end
  return dispatcher_subscribe(messages, on_message)
end

function M.unsubscribe(id)
  if not id then return end
  local sub = subscribers[id]
  if not sub then
    print("WARNING: Cannot unsubscribe unsubscribed subscriber " .. id .. ".")
    return
  end

  for i, message_id in ipairs(sub.messages) do
    local event = events[message_id]
    if event then
      event.subs[id] = nil
      event.hooks[id] = nil
    end
  end

  subscribers[id] = nil
end

local function dispatch(message_id, message)
  message_id = hash(message_id)

  local event = events[message_id]
  if not event then return end

  message = message or {}

  message_queue_active = message_queue_active + 1

  for i, sub in pairs(event.hooks) do
    sub.handler(message_id, message)
  end

  for i, sub in pairs(event.subs) do
    msg.post(sub.url, message_id, message)
  end

  if message_queue_active == 1 and next(message_queue) then
    for _, msg_desc in ipairs(message_queue) do
      dispatch(msg_desc[1], msg_desc[2])
    end
    message_queue = {}
  end
  message_queue_active = message_queue_active - 1
end

function M.dispatch(message_id, message)
  if message_queue_active > 0 then
    message_queue[#message_queue + 1] = { message_id, message }
  else
    dispatch(message_id, message)
  end
end

return M
