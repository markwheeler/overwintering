-- Migration
-- 1.0.0 @markeats @giovannilami
--
-- WIP
--

local ControlSpec = require "controlspec"

local Trove = include("lib/trove")
local Sequencer = include("lib/sequencer")
local Oystercatcher = include("lib/oystercatcher_engine")
local MapView = include("lib/map_view")
local StatsView = include("lib/stats_view")
local ClusterView = include("lib/cluster_view")
local TriggerView = include("lib/trigger_view")

engine.name = "Oystercatcher"

local update_metro

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local NUM_VIEW_MODES = 4
local view_mode = 1-- Map, Stats, Clusters, Triggers

local specs = {}
specs.TIME = ControlSpec.new(1, 12, "lin", 0, 8, "s")


-- Functions

local function bird_changed()
  Sequencer.bird_changed(params:get("species"))
end


-- Metro callbacks

local function screen_update()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
end

local function screen_dirty_callback()
  screen_dirty = true
end


-- Encoder input
function enc(n, delta)

  if n == 1 then
    params:delta("species", delta)

  elseif n == 2 then
    if params:get("play") == 1 then
      params:delta("time", delta * -1)
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

  -- Load data

  Trove.load_folder(norns.state.path .. "data/")

  local bird_names = {}

  if #Trove.bird_data == 0 then
    table.insert(bird_names, "No bird data")
  end

  -- Init sequencer
  Sequencer.screen_dirty_callback = screen_dirty_callback
  Sequencer.init(Trove)
  update_metro = metro.init(Sequencer.update)

  -- Script params
  
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
    default = 1
  }

  params:add {
    type = "control",
    id = "time",
    name = "Time",
    controlspec = specs.TIME,
    action = function(value)
      update_metro.time = value / Sequencer.STEPS_PER_SLICE
    end
  }

  -- Params
  Oystercatcher.add_chord_params()
  Oystercatcher.add_perc_params()
  Oystercatcher.add_fx_params()
  params:bang()

  -- Start metros
  metro.init(screen_update, 1 / SCREEN_FRAMERATE):start()
  update_metro:start()

end


function redraw()
  
  screen.clear()
  screen.aa(1)

  slice = Trove.get_slice(params:get("species"), Sequencer.slice_index)

  -- Map
  MapView.redraw(slice.points, view_mode == 1)

  -- Map view
  if view_mode == 1 then

    -- Top left text
    screen.level(15)
    screen.move(2, 7)
    screen.text(params:string("species"))
    -- TODO add latin name?
    screen.level(3)
    screen.move(2, 16)
    screen.text(slice.year .. " " .. slice.week)
    screen.fill()

  -- Stats view
  elseif view_mode == 2 then

    local start_slice, end_slice = Sequencer.slice_index, Sequencer.slice_index + 1
    local progress = Sequencer.step_index / Sequencer.STEPS_PER_SLICE

    local area = Trove.interp_slice_value(params:get("species"), start_slice, end_slice, progress, "area_norm")
    local mass = Trove.interp_slice_value(params:get("species"), start_slice, end_slice, progress, "num_points_norm")
    local density = Trove.interp_slice_value(params:get("species"), start_slice, end_slice, progress, "density_norm")

    StatsView.redraw(area, mass, density)

  -- Cluster view
  elseif view_mode == 3 then

    ClusterView.redraw(slice)

  -- Trigger view
  elseif view_mode == 4 then

    TriggerView.redraw(Sequencer.triggers)

  end

  -- Progress
  screen.level(3)
  screen.rect(0, 63, util.linlin(1, Trove.get_bird(params:get("species")).num_slices, 0, 128, Sequencer.slice_index + Sequencer.step_index / Sequencer.STEPS_PER_SLICE), 1)
  screen.fill()

  screen.update()
end
