--- Panning inertia.
-- @module crit.inertia
-- @todo

local filters = require "crit.filters"

local Inertia = {}

local zero3 = vmath.vector3(0.0)

function Inertia.new(options)
  options = options or {}

  local lowpass_smoothen = filters.low_pass(options.smoothen_cutoff or 15.0)
  local lowpass_friction = filters.low_pass(options.friction_cutoff or 1.0)
  local epsilon = (options.rest_epsilon or 1.0)
  local epsilon_squared = epsilon * epsilon
  local on_rest = options.on_rest
  local on_wake = options.on_wake

  local scalar = not not options.scalar
  local zero = scalar and 0 or zero3

  local self = {
    velocity = zero,
    last_velocity = zero,
    at_rest = true
  }

  local free_mode = true

  local function reset()
    self.velocity = zero
    self.last_velocity = zero
    self.at_rest = true
    free_mode = true
  end
  self.reset = reset

  local function update(dt, panned)
    if panned then
      free_mode = false
      local velocity = self.velocity
      self.last_velocity = velocity
      self.velocity = lowpass_smoothen(velocity, panned / dt, dt)
      return
    end

    if not free_mode then
      free_mode = true
      -- Discard the current frame of velocity due to touch up jitter
      self.velocity = self.last_velocity
    end

    local velocity = self.velocity
    self.last_velocity = velocity
    velocity = lowpass_friction(velocity, zero, dt)

    if
      (not scalar and vmath.length_sqr(velocity) < epsilon_squared)
      or (scalar and math.abs(velocity) < epsilon)
    then
      self.velocity = zero
      if not self.at_rest then
        self.at_rest = true
        if on_rest then on_rest() end
      end
    else
      self.velocity = velocity
      if self.at_rest then
        self.at_rest = false
        if on_wake then on_wake() end
      end
      return velocity * dt
    end
  end
  self.update = update

  return self
end

return Inertia
