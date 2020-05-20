# The `env.lua` file

In order to help with development, you can set some variables locally to
configure certain things by creating an `env.lua` file in the project root directory.

We recommend adding `env.lua` to `.gitignore` so that you don't accidentally
commit your local development flags.

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

1. Create an `env.lua` file in the project root
2. Create an `env.lua` file in the game's save directory
(`sys.get_save_file(sys.get_config("project.title"), "env.lua")`)
3. Pass it as `--env 'return { foo = 42 }'` to `dmengine`
4. On HTML5, pass it as the hash part of the URL, URL-encoded. (eg. `https://my-game.com/#return%20%7B%20foo%20%3D%2042%20%7D`)

If more than one of the above methods are used, the env tables will be merged.

