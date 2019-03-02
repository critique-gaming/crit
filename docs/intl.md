# Internationalisation

```lua
local intl = require "crit.intl"
```

The main goal here is simple: Map internationalisation keys (something like
`menu.settings.button_title`) to strings (like `Settings`) in the user's
language.

Secondarily, we might want to group our strings into separate loading units
to spare the parser from using precious CPU cycles loading strings that won't
be used. Crit achieves that with **namespaces**.

Namespaces are intl's loading unit. There's a `main` namespace you can use
directly and secondary namespaces you can load on demand.

## Setup

1. Create a directory named `intl` in the root of your project and add
it to `custom_resources`.

2. In that directory, create a Lua or a JSON file (as you wish) with your
strings. Name it `main.[lang].lua` or `main.[lang].json` respectively, where
`[lang]` is the ISO-639 language code (eg. `main.en.lua`), or a combination
of ISO-639 and ISO-3166 country code (eg. `main.en-US.lua`). In case it's a
Lua file, it must return a table with string keys and values.

3. Call `intl.init()` somewhere early on in your code (before trying to
translate any string). Before the `init()` function in your main collection is
a good place for that.

4. For any additional namespaces, create additional `[namespace_id].[lang].[lua|json]`
files.

If you don't like this string data loading mechanism, you can customise it and
use your own (`options.loader`).

## Usage

Fetching a string is as simple as `intl.translate("menu.settings.button_title")`
(or shorthand: `intl("menu.settings.button_title")`). Behind the scenes, `intl`
will go through the list of current languages and fallback languages in order
and return the string in the first language in which it exists.

This multiple language loading order allows you to add dialect layers
over a translation. For example, you can have an `en` translation and
another `en-UK` data file which overrides only the strings which sound
different in British English. Using `{ "en-UK", "en" }` as your language list will look for the strings in the `en-UK` data file and, if they're not there, fall back to the common `en` translation.

For convenience, the `intl` module is also the `main` namespace. If the string
is not in the `main` namespace, we have to load the namespace first:

```lua
local namespace = intl.namespace("menu")
print(namespace.translate("menu.settings.button_title"))
```

## API Documentation

### `intl.init(options)`

Initializes the `intl` module.

**Arguments:**
  * `options`: `table`. *Optional.* The module's configuration
    * `options.languages`: `string | table of strings` *Optional.* The list of
    current languages to use. Defaults to
    `{ language .. "-" .. territory, language }`,
    as reported by `sys.get_sys_info()`.
    * `options.fallback_languages`: `string | table of strings` *Optional.* The list
    of languages to fall back to, in case strings can't be found in any of the current
    languages. Defaults to `{ "en-US", "en" }`.
    * `options.warn_fallback`: `boolean` *Optional.* Issue console warnings if a string
    is not found in any current language and fallbacks are used. Defaults to `false`.
    * `options.strict`: `boolean` *Optional.* All warnings become errors. Defaults to `false`.
    * `options.loader`: `function (namespace_id: string, language: string)` *Optional.* Use a custom loader for string data. Must return a table with string keys and values or `nil`. Defaults to `intl.default_loader`.
    * `options.intl_dir`: `string` *Optional.* Custom resources directory where the default loaders can find the data files. Defaults to `"/intl"`

### `intl.configure(partial_options)`

Re-initializes the module with changed options. (For example, when changing
language at runtime).

**Arguments:**
  * `partial_options`: `table`. A table with the keys to change in the `options`
  table passed in `intl.init()`.

### `intl.namespace(namespace_id)`

Loads a namespace or returns it from cache, if it's already loaded.

**Remember: The `intl` module is also a namespace itself (the `main` namespace). `intl == intl.namespace("main")`**

**Arguments:**
  * `namespace_id`: `string`. The ID of the namespace to load.

**Return value:** `namespace` The requested namespace.

### `namespace.translate(key, values)`

Translates the string identified by `key`. If `values` is specified, will
replace patterns like `${foo}` in the resulting string with `values.foo`.

**Aliases:**
  * `namespace(key, values)`
  * `namespace.t(key, values)`

**Arguments:**
  * `key`: `string` The string's internationalisation key.
  * `values`: `table` *Optional.* Values for replacement patterns.

**Return value:** `string | nil`. The translated string or `nil` if not found.

### `namespace.translate_text_node(node)`

Translates the GUI text node `node` using its text as internationalisation `key`.

Effectively `gui.set_text(node, namespace.translate(gui.get_text(node)))`.

**Arguments:**
  * `node`: `gui node | string`. A GUI text node (or text node ID).

### `namespace.translate_label(url, key, values)`

Translates a label component.

Effectively `label.set_text(url, namespace.translate(key, values))`.

**Arguments:**
  * `url`: `url | hash | string`. URL to a label.
  * `key`: `string` The string's internationalisation key.
  * `values`: `table` *Optional.* Values for replacement patterns.

### `namespace.select(options)`

Select from a table (with languages as keys) a value corresponding to the
current language. Languages are tried until a non-`nil` value is found.

Instead of a table, a function can be passed instead. It will be called with
each language until it returns a non-`nil` value.

**Arguments:**
  * `options`: `table | function (language)` A table of options or an option
  resolver function.

**Return value:** The value selected from the table (or returned by the
function).

### `intl.default_loader(namespace_id, language)`

The default string data loader. Will try to use `lua_loader`, then `json_loader`.

**Arguments:**
  * `namespace_id`: `string` The name of namespace to load data for.
  * `language`: `string` The language to load data for.

**Return value:** `table | nil` A table with string data or `nil` if data file
not found for the requested namespace and language.

### `intl.lua_loader(namespace_id, language)`

Will load data from `options.intl_dir .. "/" .. namespace_id .. "." .. language .. ".lua"`.

**Arguments:**
  * `namespace_id`: `string` The name of namespace to load data for.
  * `language`: `string` The language to load data for.

**Return value:** `table | nil` A table with string data or `nil` if data file
not found for the requested namespace and language.

### `intl.json_loader(namespace_id, language)`

Will load data from `options.intl_dir .. "/" .. namespace_id .. "." .. language .. ".json"`.

**Arguments:**
  * `namespace_id`: `string` The name of namespace to load data for.
  * `language`: `string` The language to load data for.

**Return value:** `table | nil` A table with string data or `nil` if data file
not found for the requested namespace and language.
