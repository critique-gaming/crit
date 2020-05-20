# System configuration constants 

```lua
local sys_config = require "crit.sys_config"
```

This module provides a few useful constants identifying the system and engine.

|Constant|Description|
|-|-|
|`sys_config.sys_info`|The value of `sys.get_sys_info()`.|
|`sys_config.system_name`|The value of `sys.get_sys_info().system_name`.|
|`sys_config.engine_info`|The value of `sys.get_engine_info()`.|
|`sys_config.debug`|The value of `sys.get_engine_info().is_debug`.|
|`sys_config.is_mobile`|`true` on iOS and Android, `false` otherwise.|
|`sys_config.path_sep`|`"\\"` on Windows, `"/"` otherwise.|
|`sys_config.bundle_root_path`|The value of `sys.get_application_path()`, with some extra backwards compatibility.|
