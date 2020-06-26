local M = {}

local h_window_change_size = hash("window_change_size")
local h_size = hash("size")

local design_width = tonumber(sys.get_config("display.width", "960"))
local design_height = tonumber(sys.get_config("display.height", "640"))

M.design_width = design_width
M.design_height = design_height

M.design_gui_left = 0.0
M.design_gui_bottom = 0.0
M.design_gui_right = design_width
M.design_gui_top = design_height

M.design_go_left = 0.0
M.design_go_bottom = 0.0
M.design_go_right = design_width
M.design_go_top = design_height

-- There are 5 coordinate spaces:
-- 1) Window space: Raw screen coordinates inside the window. Origin is bottom left.
--    Corresponds to action.screen_x/screen_y
-- 2) Viewport space: The visible rectangle inside the window space (defined by
--    viewport_width, viewport_height, viewport_origin_x, viewport_origin_y).
--    Origin is bottom left.
-- 3) Projection space: This is where game objects live. Mapped over the viewport.
--    Its origin point is defined by projection_grav_x and projection_grav_y.
-- 4) Design space: Window space scaled to the design resolution (which
--    corresponds to action.x/action.y).
-- 5) Offset design space: Window space scaled to the design resolution (which
--    corresponds to action.x/action.y), then offset so that its origin matches
--    the viewport origin, so that gui.pick_node() works correctly if you have
--    an offset viewport.

local window_width, window_height

local viewport_width, viewport_height
local viewport_origin_x, viewport_origin_y

local design_offset_x, design_offset_y

local projection, gui_projection

local projection_width, projection_height
local projection_left, projection_right
local projection_top, projection_bottom

local viewport_to_projection_scale_x, viewport_to_projection_scale_y
local projection_to_viewport_scale_x, projection_to_viewport_scale_y
local design_to_window_scale_x, design_to_window_scale_y

function M.set_metrics(metrics)
  window_width = metrics.window_width
  window_height = metrics.window_height

  if window_width == nil or window_height == nil then
    error("metrics.window_width and metrics.window_height are required")
  end

  projection = nil
  gui_projection = nil

  M.window_width = window_width
  M.window_height = window_height

  viewport_width = metrics.viewport_width or window_width
  viewport_height = metrics.viewport_height or window_height
  viewport_origin_x = metrics.viewport_origin_x or
    math.ceil((window_width - viewport_width) * (metrics.viewport_grav_x or 0.5))
  viewport_origin_y = metrics.viewport_origin_y or
    math.ceil((window_height - viewport_height) * (metrics.viewport_grav_y or 0.5))

  M.viewport_width = viewport_width
  M.viewport_height = viewport_height
  M.viewport_origin_x = viewport_origin_x
  M.viewport_origin_y = viewport_origin_y

  projection_left = metrics.projection_left
  projection_right = metrics.projection_right
  projection_bottom = metrics.projection_bottom
  projection_top = metrics.projection_top

  if not projection_left and not projection_right and not projection_bottom and not projection_top then
    local projection_matrix = metrics.projection
    if projection_matrix then
      local inv_projection = vmath.inv(projection_matrix)
      local bottom_left = inv_projection * vmath.vector4(-1, -1, 0, 1)
      local top_right = inv_projection * vmath.vector4(1, 1, 0, 1)
      projection_left = bottom_left.x
      projection_bottom = bottom_left.y
      projection_right = top_right.x
      projection_top = top_right.y
      projection = projection_matrix
    else
      projection_left = 0
      projection_bottom = 0
      projection_right = design_width
      projection_top = design_height
    end
  end

  projection_width = projection_right - projection_left
  projection_height = projection_top - projection_bottom
  M.projection_width = projection_width
  M.projection_height = projection_height
  M.projection_left = projection_left
  M.projection_right = projection_right
  M.projection_top = projection_top
  M.projection_bottom = projection_bottom

  viewport_to_projection_scale_x = projection_width / viewport_width
  viewport_to_projection_scale_y = projection_height / viewport_height
  projection_to_viewport_scale_x = viewport_width / projection_width
  projection_to_viewport_scale_y = viewport_height / projection_height
  design_to_window_scale_x = window_width / design_width
  design_to_window_scale_y = window_height / design_height
  M.viewport_to_projection_scale_x = viewport_to_projection_scale_x
  M.viewport_to_projection_scale_y = viewport_to_projection_scale_y
  M.projection_to_viewport_scale_x = projection_to_viewport_scale_x
  M.projection_to_viewport_scale_y = projection_to_viewport_scale_y

  design_offset_x = -viewport_origin_x * (design_width / window_width)
  design_offset_y = -viewport_origin_y * (design_height / window_height)
end

M.set_metrics({
  window_width = design_width,
  window_height = design_height,
})

function M.get_projection_matrix()
  if not projection then
    projection = vmath.matrix4_orthographic(
      projection_left, projection_right,
      projection_bottom, projection_top,
      -1, 1
    )
  end
  return projection
end

function M.get_gui_projection_matrix()
  if not gui_projection then
    gui_projection = vmath.matrix4_orthographic(0, viewport_width, 0, viewport_height, -1, 1)
  end
  return gui_projection
end

-- Conversion functions

local function window_to_viewport(x, y)
  return x - viewport_origin_x, y - viewport_origin_y
end
M.window_to_viewport = window_to_viewport

local function viewport_to_window(x, y)
  return x + viewport_origin_x, y + viewport_origin_y
end
M.viewport_to_window = viewport_to_window

local function viewport_to_projection(x, y)
  local new_x = x * viewport_to_projection_scale_x + projection_left
  local new_y = y * viewport_to_projection_scale_y + projection_bottom
  return new_x, new_y
end
M.viewport_to_projection = viewport_to_projection

local function projection_to_viewport(x, y)
  local new_x = (x - projection_left) * projection_to_viewport_scale_x
  local new_y = (y - projection_bottom) * projection_to_viewport_scale_y
  return new_x, new_y
end
M.projection_to_viewport = projection_to_viewport

local function design_to_window(x, y)
  return x * design_to_window_scale_x, y * design_to_window_scale_y
end
M.design_to_window = design_to_window

local function design_to_viewport(x, y)
  return window_to_viewport(design_to_window(x, y))
end
M.design_to_viewport = design_to_viewport

local function design_to_projection(x, y)
  return viewport_to_projection(design_to_viewport(x, y))
end
M.design_to_projection = design_to_projection

local function window_to_projection(x, y)
  return viewport_to_projection(window_to_viewport(x, y))
end
M.window_to_projection = window_to_projection

local function projection_to_window(x, y)
  return viewport_to_window(projection_to_viewport(x, y))
end
M.projection_to_window = projection_to_window

function M.action_to_viewport(action)
  return window_to_viewport(action.screen_x, action.screen_y)
end

function M.action_to_projection(action)
  return window_to_projection(action.screen_x, action.screen_y)
end

local function action_to_offset_design(action)
  return action.x + design_offset_x, action.y + design_offset_y
end
M.action_to_offset_design = action_to_offset_design

function M.pick_node(node, action)
  return gui.pick_node(node, action_to_offset_design(action))
end

-- Layout instances

local function get_gui_metrics()
  return 0, 0, viewport_width, viewport_height
end

local function get_go_metrics()
  return projection_left, projection_bottom, projection_right, projection_top
end

local scale_func = {}
function scale_func.x(width, height, design_width_, design_height_, scale_x)
  return scale_x
end
function scale_func.y(width, height, design_width_, design_height_, scale_x, scale_y)
  return scale_y
end
function scale_func.fit(width, height, design_width_, design_height_, scale_x, scale_y)
  return math.min(scale_x, scale_y)
end
function scale_func.cover(width, height, design_width_, design_height_, scale_x, scale_y)
  return math.max(scale_x, scale_y)
end
function scale_func.none()
  return 1
end

M.default_scale_by = "fit"

local empty = {}

function M.new(opts)
  local self = {}

  local is_go = opts and opts.is_go or false

  self.get_metrics = opts and opts.get_metrics or
    (is_go and get_go_metrics or get_gui_metrics)

  local i_left, i_bottom, i_right, i_top
  if is_go then
    i_left = (opts and opts.design_left) or M.design_go_left
    i_bottom = (opts and opts.design_bottom) or M.design_go_bottom
    i_right = (opts and opts.design_right) or M.design_go_right
    i_top = (opts and opts.design_top) or M.design_go_top
  else
    i_left = (opts and opts.design_left) or M.design_gui_left
    i_bottom = (opts and opts.design_bottom) or M.design_gui_bottom
    i_right = (opts and opts.design_right) or M.design_gui_right
    i_top = (opts and opts.design_top) or M.design_gui_top
  end

  local initial_width = i_right - i_left
  local initial_height = i_top - i_bottom
  local initial_grav_x = -i_left / initial_width
  local initial_grav_y = -i_bottom / initial_height

  local len = 0
  local nodes = {}

  -- trigger the initial layout
  if not (opts and opts.no_initial_place) then
    msg.post("#", h_window_change_size, { width = 0, height = 0 })
  end

  function self.add_node(node, opts)
    opts = opts or empty
    len = len + 1

    local scale_by = opts.scale_by or M.default_scale_by
    if type(scale_by) == "number" then
      local const = scale_by
      scale_by = function () return const end
    elseif type(scale_by) == "string" then
      scale_by = scale_func[scale_by]
    end

    local resize = opts.resize_x or opts.resize_y or false

    local grav_x = opts.grav_x or 0.5
    local grav_y = opts.grav_y or 0.5

    local design_grav_x = grav_x - initial_grav_x
    local design_grav_y = grav_y - initial_grav_y
    local pivot = vmath.vector3(initial_width * design_grav_x, initial_height * design_grav_y, 0.0)

    local node_spec = {
      node = node,
      position = opts.position or (is_go and go.get_position(node) or gui.get_position(node)),
      scale = is_go and go.get_scale(node) or gui.get_scale(node),
      size = resize and (is_go and go.get(node, h_size) or gui.get_size(node)),
      grav_x = grav_x,
      grav_y = grav_y,
      pivot = pivot,
      scale_by = scale_by,
      resize_x = opts.resize_x or false,
      resize_y = opts.resize_y or false,
    }

    nodes[len] = node_spec
    return node_spec
  end

  function self.place()
    local left, bottom, right, top = self.get_metrics()
    local width = right - left
    local height = top - bottom

    local design_width_ = initial_width
    local design_height_ = initial_height
    local scale_x = width / design_width_
    local scale_y = height / design_height_

    local global_grav_x = -left / width
    local global_grav_y = -bottom / height

    for i, node in ipairs(nodes) do
      local grav_x = node.grav_x - global_grav_x
      local grav_y = node.grav_y - global_grav_y
      local scale = node.scale_by(width, height, design_width_, design_height_, scale_x, scale_y)
      local pivot = vmath.vector3(width * grav_x, height * grav_y, 0.0)

      local new_pos = scale * (node.position - node.pivot) + pivot
      local new_scale = node.scale * scale
      local node_id = node.node

      if is_go then
        go.set_position(new_pos, node_id)
        go.set_scale(new_scale, node_id)
      else
        gui.set_position(node_id, new_pos)
        gui.set_scale(node_id, new_scale)
      end

      local resize_x = node.resize_x
      local resize_y = node.resize_y
      if resize_x or resize_y then
        local size_x = node.size.x
        local size_y = node.size.y
        if resize_x then
          size_x = size_x + width / scale - design_width_
        end
        if resize_y then
          size_y = size_y + height / scale - design_height_
        end

        local new_size = vmath.vector3(size_x, size_y, node.size.z)
        if is_go then
          go.set(node_id, h_size, new_size)
        else
          gui.set_size(node_id, new_size)
        end
      end
    end
  end

  return self
end


return M
