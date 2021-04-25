-- Migration
-- 1.0.0 @markeats @giovannilami
--
-- WIP
--

local ControlSpec = require "controlspec"

local Trove = include("lib/trove")

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local UPDATE_RATE = 30
local update_metro

local slice_index = 1
local bird_data = {}

local NUM_VIEW_MODES = 4
local view_mode = 1-- Map, Stats, Bounds, Triggers

local specs = {}
specs.SPEED = ControlSpec.new(0.1, 4, "exp", 0, 0.25, "")


-- Functions

local function current_bird()
  return Trove.bird_data[params:get("species")]
end

local function current_slice()
  return current_bird().slices[util.round(slice_index)]
end

local function advance(step)

  local num_slices = current_bird().num_slices
  slice_index = slice_index + step
  if slice_index > num_slices then slice_index = 1 end
  if slice_index < 1 then slice_index = num_slices end

  screen_dirty = true
end

local function bird_changed()
  slice_index = 1
end

local function normalize_point(x, y)
  x = util.linlin(-180, 180, 0, 1, (x - current_bird().x_offset) * current_bird().scale)
  y = util.linlin(-90, 90, 0, 1, (y - current_bird().y_offset) * current_bird().scale)
  return x, y
end


-- Metro callbacks

local function screen_update()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
end

local function update()
  advance(params:get("speed"))
end


-- Encoder input
function enc(n, delta)

  if n == 1 then
    params:delta("species", delta)

  elseif n == 2 then
    if params:get("play") == 1 then
      params:delta("speed", delta)
    else
      advance(delta)
    end

  elseif n == 3 then
    
  end
  screen_dirty = true
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 1 then

    elseif n == 2 then
      params:delta("play", 1)

    elseif n == 3 then
      view_mode = util.wrap(view_mode + 1, 1, NUM_VIEW_MODES)
      
    end
    screen_dirty = true
  end
end


function init()

  Trove.load_folder(norns.state.path .. "data/")

  local bird_names = {}

  if #Trove.bird_data == 0 then
    table.insert(bird_names, "No bird data")
  end

  -- Add params
  
  params:add_separator("Migration")

  for _, v in ipairs(Trove.bird_data) do
    table.insert(bird_names, v.name)
  end

  params:add {
    type = "option",
    id = "species",
    name = "Species",
    options = bird_names,
    action = bird_changed
  }

  params:add {
    type = "binary",
    id = "play",
    name = "Play",
    behavior = "toggle",
    default = 1,
    action = function(value)
      if value == 1 then
        update_metro:start()
      else
        update_metro:stop()
      end
    end
  }

  params:add {
    type = "control",
    id = "speed",
    name = "Speed",
    controlspec = specs.SPEED
  }

  -- Start routines

  metro.init(screen_update, 1 / SCREEN_FRAMERATE):start()

  update_metro = metro.init(update, 1 / UPDATE_RATE)
  update_metro:start()

end


local function draw_map(points, level)

  -- screen.aa(0)

  screen.level(level)
  for _, p in ipairs(current_slice().points) do
    local nx, ny = normalize_point(p.x, p.y)
    screen.rect(nx * 128 - 0.5, 64 - ny * 64 - 0.5, 1, 1)
    screen.fill()
  end

  -- screen.aa(1)
end

function redraw()
  
  screen.clear()
  screen.aa(1)

  -- Map
  local map_level = 3
  if view_mode == 1 then map_level = 15 end
  draw_map(current_slice().points, map_level)

  -- Map view
  if view_mode == 1 then

    -- Top left text
    screen.level(15)
    screen.move(2, 7)
    screen.text(params:string("species"))
    screen.level(3)
    screen.move(2, 16)
    screen.text(current_slice().year .. " " .. current_slice().week)
    screen.fill()

  -- Stats view
  elseif view_mode == 2 then

    screen.level(15)

    -- Area
    local norm_area = util.linlin(current_bird().min_area, current_bird().max_area, 0, 1, current_slice().area)
    screen.move(2, 21)
    screen.text("Area")
    screen.fill()
    screen.rect(40, 18, util.round(norm_area * 76),  2)
    screen.fill()

    -- Mass
    local norm_mass = util.linlin(current_bird().min_points, current_bird().max_points, 0, 1, current_slice().num_points)
    screen.move(2, 30)
    screen.text("Mass")
    screen.fill()
    screen.rect(40, 27, util.round(norm_mass * 76),  2)
    screen.fill()

    -- Density
    local norm_density = util.linlin(current_bird().min_density, current_bird().max_density, 0, 1, current_slice().density)
    screen.move(2, 39)
    screen.text("Density")
    screen.fill()
    screen.rect(40, 36, util.round(norm_density * 76),  2)
    screen.fill()

  -- Bounds view
  elseif view_mode == 3 then

    -- Slice bounds
    screen.level(3)
    n_min_x, n_min_y = normalize_point(current_slice().min_x, current_slice().min_y)
    n_max_x, n_max_y = normalize_point(current_slice().max_x, current_slice().max_y)
    screen.rect(math.floor(n_min_x * 128) - 0.5, 64 - math.floor(n_max_y * 64) - 0.5, math.ceil((n_max_x - n_min_x) * 128) + 1,  math.ceil((n_max_y - n_min_y) * 64) + 1)
    screen.stroke()

    -- Cluster centroids
    screen.level(15)
    for _, c in ipairs(current_slice().clusters) do
      local norm_x, norm_y = normalize_point(c.centroid.x, c.centroid.y)
      screen.rect(util.round(norm_x * 128) - 2.5, util.round(64 - norm_y * 64) - 2.5, 4, 4)
      screen.stroke()
      -- Note: Storing number of points per cluster but probably need to normalize if using
      -- screen.move(util.round(norm_x * 128) + 4, util.round(64 - norm_y * 64) + 2)
      -- screen.text(c.num_points)
      screen.fill()
    end

  -- Triggers view
  elseif view_mode == 4 then

    local TRIG_RANGE = 3 -- LatLong Degrees
    local NUM_COLS = 6
    local NUM_ROWS = 3

    screen.level(15)
    for c = 1, NUM_COLS do
      for r = 1, NUM_ROWS do

        -- TODO move some of this outside loop
        -- TODO General cleanup of trigger code?
        local trig_x_ll = c * ((current_bird().max_x - current_bird().min_x) / (NUM_COLS + 1)) + current_bird().min_x
        local trig_y_ll = r * ((current_bird().max_y - current_bird().min_y) / (NUM_ROWS + 1)) + current_bird().min_y
        local trig_x, trig_y = normalize_point(trig_x_ll, trig_y_ll)
        trig_x = trig_x * 128
        trig_y = (1 - trig_y) * 64

        -- Detect trigger
        local trig = false
        for _, p in ipairs(current_slice().points) do
          if p.x > trig_x_ll - TRIG_RANGE and p.x < trig_x_ll + TRIG_RANGE and p.y > trig_y_ll - TRIG_RANGE and p.y < trig_y_ll + TRIG_RANGE then
            trig = true
            break
          end
        end

        -- Draw trigger
        if trig then
          screen.rect(util.round(trig_x) - 2.5, util.round(trig_y) - 2.5, 4, 4)
          screen.stroke()
        else
          screen.rect(util.round(trig_x) - 1, util.round(trig_y) - 1, 2, 2)
          screen.fill()
        end

      end
    end

  end

  -- Progress
  screen.level(3)
  screen.rect(0, 63, util.round(util.linlin(1, current_bird().num_slices, 0, 128, slice_index)), 1)
  screen.fill()

  screen.update()
end
