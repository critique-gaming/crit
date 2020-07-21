--- System configuration constants.
-- @module crit.sys_config
-- @todo

local sys_info = sys.get_sys_info()
local system_name = sys_info.system_name
local is_mobile = system_name == "iPhone OS" or system_name == "Android"

local engine_info = sys.get_engine_info()
local debug = engine_info.is_debug

local path_sep = system_name == "Windows" and "\\" or "/"

-- sys.get_application_path() is broken on Linux
local bundle_root_path = ((system_name ~= "Linux" and sys.get_application_path)
  or (fmod and fmod.get_bundle_root)
  or (defos and defos.get_bundle_root)
  or (function () return "." end)
)()

return {
  sys_info = sys_info,
  system_name = system_name,
  engine_info = engine_info,
  debug = debug,
  is_mobile = is_mobile,
  path_sep = path_sep,
  bundle_root_path = bundle_root_path,
}
