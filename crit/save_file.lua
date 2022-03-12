local table_util = require "crit.table_util"

local M = {}

local game_name = sys.get_config("project.title")

function M.get_save_file(name)
  return sys.get_save_file(game_name, name)
end

local function check_version(data, version, migrate)
  data.version = data.version or 0

  if data.version > version then
    error("Save file created by a newer version of the game")
  end
  if data.version < version and migrate then
    data = migrate(data, data.version, version)
  end

  return data
end

function M.get_config(file_path, options)
  options = options or {}

  local data = sys.load(file_path) or {}
  if options.defaults then
    setmetatable(data, { __index = options.defaults })
  end

  data = check_version(data, options.version or 1, options.migrate)

  local callback = options.callback

  local meta = {
    __index = data,
    __newindex = function (_, k, v)
      local old_value = data[k] -- Takes into account defaults
      if rawget(data, k) ~= v then
        data[k] = v
        sys.save(file_path, data)
      end
      if callback and old_value ~= v then
        callback(k, v, old_value)
      end
    end
  }

  local self = {}
  setmetatable(self, meta)
  return self
end

function M.get_profile(save_path, options)
  options = options or {}
  local data

  local version = options.version or 1

  local function load()
    data = sys.load(save_path) or {}
    data = check_version(data, version, options.migrate)
    return data
  end

  local function get()
    if data == nil then
      return load()
    else
      return data
    end
  end

  local function save(new_data)
    data = new_data
    data.version = version
    sys.save(save_path, new_data)
    if options.on_save then
      options.on_save(new_data)
    end
  end

  local function duplicate_from_profile(other_profile)
    save(table_util.deep_clone(other_profile.get()))
  end

  return {
    load = load,
    get = get,
    save = save,
    duplicate_from_profile = duplicate_from_profile,
  }
end

function M.get_memory_profile(data, options)
  options = options or {}
  local version = options.version or 1

  data = check_version(data, version, options.migrate)

  local function load()
    return data
  end

  local function save(new_data)
    data = new_data
    new_data = version
    if options.on_save then
      options.on_save(new_data)
    end
  end

  local function duplicate_from_profile(other_profile)
    save(table_util.deep_clone(other_profile.get()))
  end

  return {
    load = load,
    get = load,
    save = save,
    duplicate_from_profile = duplicate_from_profile,
  }
end

function M.get_save_profile(index, name)
  name = name or "save"
  return M.get_profile(M.get_save_file(name .. "_" .. tostring(index)))
end

return M
