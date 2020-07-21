--- The environment file.
-- @module crit.env
-- @todo

local sys_config = require "crit.sys_config"

local function load_from_resource()
  local file = sys.load_resource(sys.get_config("crit.env_file", "/_env/env.lua"))
  if not file then return {} end
  local chunk, error = loadstring(file or "")
  if not chunk then
    print(error)
    return {}
  end
  return chunk() or {}
end

local function load_from_parameters(env)
  local luastring
  if html5 then
    luastring = html5.run([[
      decodeURIComponent(window.location.hash.substring(1))
    ]])
  else
    if not defos then return end
    local args = defos.get_parameters()
    for i, arg in ipairs(args) do
      if args == '--env' then
        luastring = args[i + 1]
        break
      end
    end
  end

  if not luastring or luastring == "" then return end
  local chunk, error = loadstring(luastring)
  if not chunk then
    print(error)
    return
  end

  local new_env = chunk()
  for k, v in pairs(new_env) do
    env[k] = v
  end
end

local function load_from_save(env)
  local game_name = sys.get_config("project.title")
  local save_path = sys.get_save_file(game_name, "env.lua")

  local f = io.open(save_path)
  if not f then return end

  print("Found env.lua save file overrides")

  local luastring = f:read("*all")
  f:close()

  if not luastring or luastring == "" then return end
  local chunk, error = loadstring(luastring)
  if not chunk then
    print(error)
    return
  end

  local new_env = chunk()
  for k, v in pairs(new_env) do
    env[k] = v
  end
end

local debug = sys_config.debug
local function config_enabled(config_key)
  local value = sys.get_config(config_key .. (debug and "_debug" or "_release"), debug and "1" or "0")
  return value == "1" or value == "true"
end

local env
env = config_enabled("crit.env_from_resource") and load_from_resource() or {}

if config_enabled("crit.env_from_save") then
  load_from_save(env)
end

if config_enabled("crit.env_from_parameters") then
  load_from_parameters(env)
end

return env
