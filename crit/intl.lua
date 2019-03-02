local languages = {}
local fallback_languages = {}
local warn_fallback = false
local intl_dir = ""
local uninitialized = true

local function uninitialized_error()
  error("intl functions cannot be called before intl.init()", 2)
end

local function lua_loader(namespace_id, language)
  local file = sys.load_resource(intl_dir .. "/" .. namespace_id .. "." .. language .. ".lua")
  if not file then return nil end

  local chunk, parse_error = loadstring(file)
  if not chunk then
    print(parse_error)
    return nil
  end

  local data
  local status, error = pcall(function ()
    data = chunk()
  end)

  if not status then
    print(error)
    return nil
  end

  return data
end

local function json_loader(namespace_id, language)
  local file = sys.load_resource(intl_dir .. "/" .. namespace_id .. "." .. language .. ".json")
  if not file then return nil end

  local data
  local status, error = pcall(function ()
    data = json.decode(file)
  end)

  if not status then
    print(error)
    return nil
  end

  return data
end

local function default_loader(namespace_id, language)
  return lua_loader(namespace_id, language) or json_loader(namespace_id, language)
end

local loader = default_loader

local strict = false

local function warn(message, show_trace)
  if strict then
    error(message, 3)
  else
    if show_trace and debug then
      print("WARNING: " .. debug.traceback(message, 3))
    else
      print("WARNING: " .. message)
    end
  end
end

local function make_namespace(namespace_id)
  local lang_data
  local lang_count = 0
  local lang_fallback = 0

  local function load()
    lang_data = {}
    lang_count = 0

    local cache = {}

    for i, lang in ipairs(languages) do
      local loaded_data = cache[lang] or loader(namespace_id, lang)
      cache[lang] = loaded_data
      if loaded_data then
        lang_count = lang_count + 1
        lang_data[lang_count] = loaded_data
      end
    end

    lang_fallback = lang_count

    for i, lang in ipairs(fallback_languages) do
      local loaded_data = cache[lang] or loader(namespace_id, lang)
      cache[lang] = loaded_data
      if loaded_data then
        lang_count = lang_count + 1
        lang_data[lang_count] = loaded_data
      end
    end
  end

  local function get_entry(key)
    for i = 1, lang_count do
      local entry = lang_data[i][key]
      if entry then
        if warn_fallback and i > lang_fallback then
          warn("Match not found for intl key \"" .. key .. "\". Using fallback language")
        end
        return entry
      end
    end
    warn("Match not found for intl key \"" .. key .. "\"", true)
    return key
  end

  local function translate(key, values)
    if uninitialized then uninitialized_error() end
    local entry = get_entry(key)
    if not values then
      return entry
    end
    return string.gsub(entry, "${([a-zA-Z_][a-zA-Z_0-9]*)}", values)
  end

  local function translate_text_node(node)
    if uninitialized then uninitialized_error() end
    if type(node) == "string" then
      node = gui.get_node(node)
    end
    local text = translate(gui.get_text(node))
    gui.set_text(node, text)
    return text
  end

  local function translate_label(url, key, values)
    if uninitialized then uninitialized_error() end
    local text = translate(key, values)
    label.set_text(url, text)
    return text
  end

  local function select(options)
    if uninitialized then uninitialized_error() end

    local is_function = type(options) == "function"

    for i, lang in ipairs(languages) do
      local entry
      if is_function then
        entry = options(lang)
      else
        entry = options[lang]
      end
      if entry ~= nil then return entry end
    end

    for i, lang in ipairs(fallback_languages) do
      local entry
      if is_function then
        entry = options(lang)
      else
        entry = options[lang]
      end
      if entry ~= nil then
        if warn_fallback then
          warn("Intl match not found for selection. Using fallback language")
        end
        return entry
      end
    end

    warn("Intl match not found for selection", true)
    return nil
  end

  local public = {
    t = translate,
    translate = translate,
    translate_text_node = translate_text_node,
    translate_label = translate_label,
    select = select,
  }
  setmetatable(public, {
    __call = function (t, key, values)
      return translate(key, values)
    end,
  })

  local private = {
    load = load,
  }

  load()
  return public, private
end

local M, M_private = make_namespace("main")
local namespaces = { main = M }

local namespace_privates = { [M] = M_private }
setmetatable(namespace_privates, { __mode = "k" })

local function reload()
  for public, private in pairs(namespace_privates) do
    private.load()
  end
end

local function to_array(lang)
  if not lang then return nil end
  if type(lang) == "string" then return { lang } end
  return lang
end

function M.init(options)
  languages = to_array(options and (options.languages or options.language))
  if not languages then
    local sys_info = sys.get_sys_info()
    languages = {
      sys_info.language .. "-" .. sys_info.territory,
      sys_info.language,
    }
  end

  fallback_languages = to_array(options and (options.fallback_languages or options.fallback_language))
  if not fallback_languages then
    fallback_languages = { "en-US", "en" }
  end

  if options and options.loader then
    loader = options.loader
  end

  intl_dir = (options and options.intl_dir) or "/intl"
  warn_fallback = not not (options and options.warn_fallback)
  strict = not not (options and options.strict)

  uninitialized = false

  reload()
end

function M.configure(options)
  if uninitialized then uninitialized_error() end
  if not options then return end

  languages = to_array(options.languages or options.language) or languages
  fallback_languages = to_array(options.fallback_languages or options.fallback_language) or fallback_languages
  if options.warn_fallback ~= nil then
    warn_fallback = not not options.warn_fallback
  end
  if options.strict ~= nil then
    strict = not not options.strict
  end
  loader = options.loader or loader
  intl_dir = options.intl_dir or intl_dir

  reload()
end

function M.namespace(namespace_id)
  local namespace = namespaces[namespace_id]
  if not namespace then
    local public, private = make_namespace(namespace_id)
    namespaces[namespace_id] = public
    namespace_privates[public] = private
    namespace = public
  end
  return namespace
end

M.lua_loader = lua_loader
M.json_loader = json_loader
M.default_loader = default_loader

return M
