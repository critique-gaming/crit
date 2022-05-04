--- Helper module for reacting to typed cheat codes
-- @module crit.cheatcodes

local h_text = hash("text")

local M = {}

M.codes = {}

function M.init(codes)
  local code_list = {}
  M.codes = code_list

  for code, action in pairs(codes) do
    code_list[#code_list+1] = {
      text = code,
      action = action,
      progress = 1,
    }
  end
end

local function on_text(text)
  local len = #text
  for i = 1, len do
    local char = text:byte(i, i)
    for _, code in ipairs(M.codes) do
      if char == code.text:byte(code.progress) then
        code.progress = code.progress + 1
        if code.progress > #code.text then
          code.progress = 1
          code.action()
        end
      else
        code.progress = 1
      end
    end
  end
end
M.on_text = on_text

function M.on_input(action_id, action)
  if action_id == h_text then
    on_text(action.text)
  end
end

return M
