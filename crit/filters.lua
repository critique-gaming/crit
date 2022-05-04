--[[--
  Filters.

  Small module that implements low-pass and high-pass filters. Useful in animation
  for smoothing out a signal (low-pass) or for focusing on fast changes in the
  signal (high-pass).

  **Usage example:**
  [examples/filters/filters.script](https://github.com/critique-gaming/crit/blob/master/examples/filters/filters.script)
]]
-- @module crit.filters

local M = {}

-- luacheck: push no max line length

--[[--
  Create a low pass filter.

  ![Low-pass filter applied on step signal](https://github.com/critique-gaming/crit/raw/master/docs/filters-low-pass.png)

  [Low-pass filters](https://en.wikipedia.org/wiki/Low-pass_filter) remove high
  frequencies from a signal, which effectively smoothens it out.
  This makes them useful, for example, for smoothly animating a value towards a rapidly changing target
  value without having to continuously cancel and
  re-start animations or worry about fixed animation
  durations.
]]--
-- @tparam number cutoff_frequency The cut-off frequency (in Hz) of the filter.
-- @treturn LowPassFilter The new filter function.
function M.low_pass(cutoff_frequency)
  local RC = 1.0 / (cutoff_frequency * 2.0 * math.pi);
  return function (previous_output, input, dt)
    local alpha = dt / (dt + RC);
    return previous_output + alpha * (input - previous_output);
  end
end

--- A low pass filter function returned by @{low_pass}.
-- @function LowPassFilter
-- @number previous_output The last output, as returned by the previous call to this function.
-- @number input The value of the input signal sample that is to be filtered.
-- @number dt Time elapsed (in seconds) since the last call to this function.
-- @treturn number The current output of the filter.


--[[--
  Create a high pass filter.

  ![High-pass filter applied on step signal](https://github.com/critique-gaming/crit/raw/master/docs/filters-high-pass.png)

  [High-pass filters](https://en.wikipedia.org/wiki/High-pass_filter) remove low frequencies from
  a signal, leaving out only the high frequencies. This is useful for situations where you need to track
  abrupt momentary changes.
]]--
-- @tparam number cutoff_frequency The cut-off frequency (in Hz) of the filter.
-- @treturn HighPassFilter The new filter function.
function M.high_pass(cutoff_frequency)
  local RC = 1.0 / (cutoff_frequency * 2.0 * math.pi);
  return function (previous_output, delta_input, dt)
    local alpha = RC / (dt + RC);
    return alpha * (previous_output + delta_input);
  end
end

-- luacheck: pop

--- A high pass filter function returned by @{high_pass}.
-- @function HighPassFilter
-- @number previous_output The last output, as returned by the previous call to this function.
-- @number delta_input The relative change of the input signal sample value since the last call to this function.
-- @number dt Time elapsed (in seconds) since the last call to this function.
-- @treturn number The current output of the filter.

return M
