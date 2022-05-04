--- Toggle actions by tapping a sequence of screen corners (useful to trigger a debug overlay on mobile, for example)
-- @module crit.hotspots

local Layout = require "crit.layout"

local h_click = hash("click")

local M = {}

function M.init(sequences)
  M.hotspot_sequences = sequences
  M.hotspot_pressed = false

  -- Do a bit of KMP
  for _, seq in ipairs(M.hotspot_sequences) do
    local fail = { 0 }
    local cnd = 1
    for pos = 2, #seq do
      if seq[pos] == seq[cnd] then
        fail[pos] = fail[cnd]
      else
        fail[pos] = cnd
        cnd = fail[cnd]
        while cnd >= 1 and seq[pos] ~= seq[cnd] do
          cnd = fail[cnd]
        end
      end
      cnd = cnd + 1
    end
    seq.fail = fail
  end
end

function M.on_input(action_id, action)
  if action_id == h_click then
    if action.pressed then
      local hotspot
      local low_x = action.screen_x <= 100
      local high_x = action.screen_x >= Layout.window_width - 100
      local low_y = action.screen_y <= 100
      local high_y = action.screen_y >= Layout.window_height - 100

      if low_x and low_y then
        hotspot = 0
      elseif high_x and low_y then
        hotspot = 1
      elseif low_x and high_y then
        hotspot = 2
      elseif high_x and high_y then
        hotspot = 3
      end

      M.hotspot_pressed = false
      if not hotspot then return end

      local hotspot_pressed = false
      local hotspot_pressed_not_first = false
      for _, seq in ipairs(M.hotspot_sequences) do
        while seq.pos >= 1 and seq[seq.pos] ~= hotspot do
          seq.pos = seq.fail[seq.pos]
        end
        if seq.pos < 1 then seq.pos = 1 end

        if seq[seq.pos] == hotspot then
          hotspot_pressed = true
          if seq.pos > 1 then
            hotspot_pressed_not_first = true
          end
          if seq.pos == #seq then
            seq.pos = 1
            seq.action()
          else
            seq.pos = seq.pos + 1
          end
        end
      end

      M.hotspot_pressed = hotspot_pressed_not_first
      if not hotspot_pressed then return end

      if M.hotspot_timer then
        timer.cancel(M.hotspot_timer)
        M.hotspot_timer = nil
      end

      M.hotspot_timer = timer.delay(5.0, false, function ()
        M.hotspot_timer = nil
        for _, seq in ipairs(M.hotspot_sequences) do
          seq.pos = 1
        end
      end)

      return hotspot_pressed_not_first

    elseif action.released then
      local hotspot_pressed = M.hotspot_pressed
      M.hotspot_pressed = false
      return hotspot_pressed
    end

    return M.hotspot_pressed
  end
end

return M
