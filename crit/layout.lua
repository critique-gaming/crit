local Layout = { __index = {} }

local h_window_change_size = hash("window_change_size")
local h_size = hash("size")

local design_width = tonumber(sys.get_config("display.width", "960"))
local design_height = tonumber(sys.get_config("display.height", "640"))

Layout.design_width = design_width
Layout.design_height = design_height

-- There are 4 coordinate spaces:
-- 1) Window space: Raw screen coordinates inside the window. Origin is bottom left.
--    Corresponds to action.screen_x/screen_y
-- 2) Viewport space: The visible rectangle inside the window space (defined by
--    viewport_width, viewport_height, viewport_origin_x, viewport_origin_y).
--    Origin is bottom left.
-- 3) Projection space: This is where game objects live. Mapped over the viewport.
--    Its origin point is defined by projection_grav_x and projection_grav_y.
-- 4) Offset design space: Window space scaled to the design resolution (which
--    corresponds to action.x/action.y), then offset so that its origin matches
--    the viewport origin.

local window_width, window_height
local viewport_width, viewport_height
local projection_width, projection_height

local viewport_origin_x, viewport_origin_y
local projection_origin_x, projection_origin_y
local projection_scale_x, projection_scale_y
local design_offset_x, design_offset_y

function Layout.set_metrics(metrics)
  window_width = metrics.window_width
  window_height = metrics.window_height
  if window_width == nil or window_height == nil then
    error("metrics.window_width and metrics.window_height are required")
  end
  viewport_width = metrics.viewport_width or window_width
  viewport_height = metrics.viewport_height or window_height
  projection_width = metrics.projection_width or viewport_width
  projection_height = metrics.projection_height or viewport_height

  Layout.window_width = window_width
  Layout.window_height = window_height
  Layout.viewport_width = viewport_width
  Layout.viewport_height = viewport_height
  Layout.projection_width = projection_width
  Layout.projection_height = projection_height

  Layout.viewport_grav_x = metrics.viewport_grav_x or 0.5
  Layout.viewport_grav_y = metrics.viewport_grav_y or 0.5
  Layout.gui_grav_x = metrics.gui_grav_x or 0.0
  Layout.gui_grav_y = metrics.gui_grav_y or 0.0
  Layout.projection_grav_x = metrics.projection_grav_x or 0.0
  Layout.projection_grav_y = metrics.projection_grav_y or 0.0

  viewport_origin_x = metrics.viewport_origin_x or
    math.ceil((window_width - viewport_width) * Layout.viewport_grav_x)
  viewport_origin_y = metrics.viewport_origin_y or
    math.ceil((window_height - viewport_height) * Layout.viewport_grav_y)
  Layout.viewport_origin_x = viewport_origin_x
  Layout.viewport_origin_y = viewport_origin_y

  projection_scale_x = projection_width / viewport_width
  projection_scale_y = projection_height / viewport_height
  projection_origin_x = viewport_width * Layout.projection_grav_x
  projection_origin_y = viewport_height * Layout.projection_grav_y
  Layout.projection_scale_x = projection_scale_x
  Layout.projection_scale_y = projection_scale_y

  design_offset_x = -viewport_origin_x * (design_width / window_width)
  design_offset_y = -viewport_origin_y * (design_height / window_height)
end

Layout.set_metrics({
  window_width = design_width,
  window_height = design_height,
})

function Layout.get_projection_matrix()
  local offset_x = -projection_width * Layout.projection_grav_x;
  local offset_y = -projection_height * Layout.projection_grav_y;
  return vmath.matrix4_orthographic(
    offset_x, offset_x + projection_width,
    offset_y, offset_y + projection_height,
    -1, 1
  )
end

function Layout.get_gui_projection_matrix()
  return vmath.matrix4_orthographic(0, viewport_width, 0, viewport_height, -1, 1)
end

-- Conversion functions

function Layout.get_viewport_metrics()
  return viewport_width, viewport_height
end

function Layout.get_projection_metrics()
  return projection_width, projection_height
end

local function window_to_viewport(x, y)
  return x - viewport_origin_x, y - viewport_origin_y
end
Layout.window_to_viewport = window_to_viewport

local function viewport_to_window(x, y)
  return x + viewport_origin_x, y + viewport_origin_y
end
Layout.viewport_to_window = viewport_to_window

local function viewport_to_projection(x, y)
  return (x - projection_origin_x) * projection_scale_x, (y - projection_origin_y) * projection_scale_y
end
Layout.viewport_to_projection = viewport_to_projection

local function projection_to_viewport(x, y)
  return (x / projection_scale_x) + projection_origin_x, (y / projection_scale_y) + projection_origin_y
end
Layout.projection_to_viewport = projection_to_viewport

local function window_to_projection(x, y)
  return viewport_to_projection(window_to_viewport(x, y))
end
Layout.window_to_projection = window_to_projection

local function projection_to_window(x, y)
  return viewport_to_window(projection_to_viewport(x, y))
end
Layout.projection_to_window = projection_to_window

function Layout.action_to_viewport(action)
  return window_to_viewport(action.screen_x, action.screen_y)
end

function Layout.action_to_projection(action)
  return window_to_projection(action.screen_x, action.screen_y)
end

local function action_to_offset_design(action)
  return action.x + design_offset_x, action.y + design_offset_y
end
Layout.action_to_offset_design = action_to_offset_design

function Layout.pick_node(node, action)
  return gui.pick_node(node, action_to_offset_design(action))
end

-- Layout instances

function Layout.new(opts)
  local self = {}
  setmetatable(self, Layout)

  local is_go = opts and opts.is_go or false

  self.is_go = is_go
  self.orig_width = opts and opts.width or design_width
  self.orig_height = opts and opts.height or design_height
  self.get_metrics = opts and opts.get_metrics or
    (is_go and Layout.get_projection_metrics or Layout.get_viewport_metrics)
  self.grav_x = opts and opts.grav_x or
    (is_go and Layout.projection_grav_x or Layout.gui_grav_x)
  self.grav_y = opts and opts.grav_y or
    (is_go and Layout.projection_grav_y or Layout.gui_grav_y)

  self.len = 0
  self.nodes = {}

  -- trigger the initial layout
  if not (opts and opts.no_initial_place) then
    msg.post("#", h_window_change_size, { width = 0, height = 0 })
  end

  return self
end

function Layout.hook(self, message)
  self.layout:place()
end

local scale_func = {}
function scale_func.x(width, height, original_width, original_height, scale_x)
  return scale_x
end
function scale_func.y(width, height, original_width, original_height, scale_x, scale_y)
  return scale_y
end
function scale_func.fit(width, height, original_width, original_height, scale_x, scale_y)
  return math.min(scale_x, scale_y)
end
function scale_func.cover(width, height, original_width, original_height, scale_x, scale_y)
  return math.max(scale_x, scale_y)
end
function scale_func.none()
  return 1
end

Layout.scale_by_default = "x"

local empty = {}
function Layout.__index:add_node(node, opts)
  opts = opts or empty
  self.len = self.len + 1

  local scale_by = opts.scale_by or Layout.scale_by_default
  if type(scale_by) == "number" then
    local const = scale_by
    scale_by = function () return const end
  elseif type(scale_by) == "string" then
    scale_by = scale_func[scale_by]
  end

  local resize = opts.resize_x or opts.resize_y or false
  local is_go = self.is_go

  local node_spec = {
    node = node,
    position = opts.position or (is_go and go.get_position(node) or gui.get_position(node)),
    scale = is_go and go.get_scale(node) or gui.get_scale(node),
    size = resize and (is_go and go.get(node, h_size) or gui.get_size(node)),
    grav_x = opts.grav_x or 0.5,
    grav_y = opts.grav_y or 0.5,
    scale_by = scale_by,
    resize_x = opts.resize_x or false,
    resize_y = opts.resize_y or false,
  }

  self.nodes[self.len] = node_spec
  return node_spec
end

function Layout.__index:place(width, height)
  if width == 0 then width = false end
  if height == 0 then height = false end

  local m_width, m_height = self.get_metrics()

  width = width or m_width
  height = height or m_height
  local orig_height = self.orig_height
  local orig_width = self.orig_width
  local scale_x = width / orig_width
  local scale_y = height / orig_height
  local is_go = self.is_go
  local global_grav_x = self.grav_x
  local global_grav_y = self.grav_y

  for i, node in ipairs(self.nodes) do
    local grav_x = node.grav_x - global_grav_x
    local grav_y = node.grav_y - global_grav_y
    local scale = node.scale_by(width, height, orig_width, orig_height, scale_x, scale_y)
    local orig_pivot = vmath.vector3(orig_width * grav_x, orig_height * grav_y, 0.0)
    local pivot = vmath.vector3(width * grav_x, height * grav_y, 0.0)

    local new_pos = scale * (node.position - orig_pivot) + pivot
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
        size_x = size_x + width / scale - orig_width
      end
      if resize_y then
        size_y = size_y + height / scale - orig_height
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

return Layout