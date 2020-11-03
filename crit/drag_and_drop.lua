--- Drag and drop.
-- @module crit.drag_and_drop
-- @todo

local pick = require "crit.pick"

local default_action_to_position = function (action)
  return action.x, action.y
end

local DragAndDrop = {
  __index = {},
  default_gui_action_to_position = default_action_to_position,
  default_sprite_action_to_position = default_action_to_position,
  click_action_id = hash("touch"),
}

local nop = function () end
local always = function () return true end
local DragAndDrop__move_source

function DragAndDrop.new(options)
  local self = {}
  setmetatable(self, DragAndDrop)

  self.drag_sources = options.drag_sources or {}
  self.drop_targets = options.drop_targets or {}

  self.can_drag = options.can_drag or always
  self.can_drop = options.can_drop or always
  self.on_drag_start = options.on_drag_start or nop
  self.on_drag_move = options.on_drag_move or DragAndDrop__move_source
  self.on_drag_cancel = options.on_drag_cancel or nop
  self.on_drag_commit = options.on_drag_commit or nop
  self.on_manual_drag_move = options.on_manual_drag_move or nop

  self.manually_dragging = false
  self.current_drag_source = nil
  self.current_drop_target = nil

  return self
end

local function DragAndDrop__pick(source_or_target, action)
  local node = source_or_target.node

  local custom_pick = source_or_target.pick
  if custom_pick then
    return custom_pick(source_or_target, action)
  end

  if node then
    local x, y = DragAndDrop.default_gui_action_to_position(action)
    return gui.pick_node(node, x, y)
  end

  local sprite = source_or_target.sprite
  if sprite then
    local x, y = DragAndDrop.default_sprite_action_to_position(action)
    return pick.pick_sprite(sprite, x, y, source_or_target.padding)
  end

  return false
end

local function DragAndDrop__get_picked_item(source_or_targets, action, predicate)
  for i, source_or_target in ipairs(source_or_targets) do
    if (not predicate or predicate(source_or_target)) and DragAndDrop__pick(source_or_target, action) then
      return source_or_target
    end
  end
  return nil
end

local function DragAndDrop__action_to_position(source_or_target, action)
  local node = source_or_target.node
  if node then
    local x, y = DragAndDrop.default_gui_action_to_position(action)
    return x, y
  end

  local sprite = source_or_target.sprite
  if sprite then
    local x, y = DragAndDrop.default_sprite_action_to_position(action)
    return x, y
  end

  return action.x, action.y
end

function DragAndDrop__move_source(drag_source, dx, dy)
  local node = drag_source.node
  if node then
    gui.set_position(node, gui.get_position(node) + vmath.vector3(dx, dy, 0))
    return
  end

  local go_id = drag_source.go or drag_source.sprite
  if go_id then
    go.set_position(go.get_position(go_id) + vmath.vector3(dx, dy, 0), go_id)
    return
  end
end

function DragAndDrop.__index:on_input(action_id, action)
  if action_id == DragAndDrop.click_action_id and not self.manually_dragging then
    if action.pressed then
      local drag_source = DragAndDrop__get_picked_item(self.drag_sources, action)
      if drag_source and self.can_drag(drag_source) then
        self.current_drag_source = drag_source
        self.x, self.y = DragAndDrop__action_to_position(drag_source, action)
        self.on_drag_start(drag_source)
      else
        self.current_drag_source = nil
      end
    else
      local drag_source = self.current_drag_source
      if drag_source then
        local x, y = DragAndDrop__action_to_position(drag_source, action)
        local dx, dy = x - self.x, y - self.y
        self.x, self.y = x, y
        self.on_drag_move(drag_source, dx, dy)

        if action.released then
          self.current_drag_source = nil
          local drop_target = DragAndDrop__get_picked_item(self.drop_targets, action, function (target)
            return self.can_drop(drag_source, target)
          end)
          if drop_target then
            self.on_drag_commit(drag_source, drop_target)
          else
            self.on_drag_cancel(drag_source)
          end
        end
      end
    end
  end
end

function DragAndDrop.__index:manual_drag_start(drag_source)
  local current_drag_source = self.current_drag_source
  if current_drag_source then
    self.current_drag_source = nil
    self.on_drag_cancel(current_drag_source)
  end

  self.manually_dragging = true
  self.current_drag_source = drag_source
  self.current_drop_target = nil
  self.on_drag_start(drag_source)
end

function DragAndDrop.__index:manual_drag_move(drop_target)
  if not self.manually_dragging then return end
  local drag_source = self.current_drag_source
  if not drag_source then return end

  local can_drag = self.can_drag(drag_source, drop_target)
  if can_drag then
    self.current_drop_target = drop_target
    self.on_manual_drag_move(drag_source, drop_target)
  end
  return can_drag
end

function DragAndDrop.__index:manual_drag_commit()
  local drag_source = self.current_drag_source
  local drop_target = self.current_drop_target
  if not drag_source or not drop_target then return end

  self.manually_dragging = false
  self.current_drag_source = nil
  self.current_drop_target = nil

  self.on_drag_commit(drag_source, drop_target)
end

function DragAndDrop.__index:drag_cancel()
  local drag_source = self.current_drag_source
  if not drag_source then return end

  self.manually_dragging = false
  self.current_drag_source = nil
  self.current_drop_target = nil

  self.on_drag_cancel(drag_source)
end

function DragAndDrop.__index:is_dragging()
  return not not self.current_drag_source
end

return DragAndDrop