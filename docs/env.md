# The `env.lua` file

In order to help with development, you can set some variables locally to
configure certain things by creating an `_env/env.lua` file in the project root directory.

We recommend adding `_env/env.lua` to `.gitignore` so that you don't accidentally
commit your local development flags.

## Setup

```bash
# Create the _env dir
mkdir _env

# Add a dummy file so that git makes sure the dir always exists
touch _env/.empty  

# You don't want to accidentally commit your local development flags
echo "/_env/env.lua" >> .gitignore
```

Then add the `_env` dir to `project.custom_resources` in `game.project`.

## Usage

You must return a table from `env.lua` with your config vars.

Let's say your `env.lua` looks like this:

```lua
return {
  some_config_var = 12,
}
```

In your code you can then access `some_config_var` as such:

```lua
local env = require "crit.env"
print(env.some_config_var) -- 12
```

## Alternative ways to add variables to the `env` table

There are multiple ways to pass an env table to the game:

1. As explained above, create an `_env/env.lua` file in the project root.  
  (Or if you prefer a different path for the `env.lua` file, set `crit.env_file` in `game.project` to your desired path. `crit.env_file` defaults to `_env/env.lua`).

2. *Debug builds only:* Create an `env.lua` file in the game's save directory.
(`sys.get_save_file(sys.get_config("project.title"), "env.lua")`)

3. *Debug builds only:* Pass it as `--env 'return { foo = 42 }'` to `dmengine`.

4. *Debug builds only:* On HTML5, pass it as the hash part of the URL, URL-encoded. (eg. `https://my-game.com/#return%20%7B%20foo%20%3D%2042%20%7D`)

If more than one of the above methods are used, the env tables will be merged.

