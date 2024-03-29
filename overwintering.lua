-- Overwintering
-- 1.0.0 @markeats
-- llllllll.co/t/overwintering
--
-- Bird migration patterns.
--
-- E2 : Species
-- E3 : Scrub time
-- K2 : View
-- K3 : Play / Pause
--
-- Sound and code Mark Eats.
-- Concept Giovanni Lami &
-- Elisabetta Reali.
-- Data and consulting
-- Gabriel Gargallo.
-- EuroBirdPortal.org
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

local VIEW_SLICES = 4 -- Num slices show before view cycles
local NUM_VIEW_MODES = 4
local view_mode = 1 -- Map, Stats, Clusters, Triggers
local view_countdown = VIEW_SLICES

local specs = {}
specs.TIME = ControlSpec.new(0.1, 12, "lin", 0, 6.8, "s")


-- Functions

local function bird_changed()
  Sequencer.bird_changed(params:get("species"))
  view_mode = 1
  view_countdown = VIEW_SLICES
end


-- Callbacks

local function screen_update()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
end

local function screen_dirty_callback()
  screen_dirty = true
end

local function slice_changed_callback()
  -- Cycle views
  if params:get("cycle_views") > 0 then
    view_countdown = view_countdown - 1
    if view_countdown <= 0 then
      view_mode = util.wrap(view_mode + 1, 1, NUM_VIEW_MODES)
      view_countdown = VIEW_SLICES
    end
  end
end


-- Encoder input
function enc(n, delta)

  if n == 2 then
    params:delta("species", delta)

  elseif n == 3 then
    Sequencer.slice_delta(util.round(delta))

  end

  screen_dirty = true
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 1 then

    elseif n == 2 then
      params:set("cycle_views", 0)
      view_mode = util.wrap(view_mode + 1, 1, NUM_VIEW_MODES)

    elseif n == 3 then
      params:delta("play", 1)
      
    end
    screen_dirty = true
  end
end


function init()

  -- Load data

  Trove.load_birds(norns.state.path .. "data/")

  local bird_names = {}

  if #Trove.bird_data == 0 then
    table.insert(bird_names, "No bird data")
  end

  -- Init sequencer
  Sequencer.screen_dirty_callback = screen_dirty_callback
  Sequencer.slice_changed_callback = slice_changed_callback
  Sequencer.init(Trove)
  update_metro = metro.init(Sequencer.update)

  -- Script params
  
  params:add_separator("Overwintering")

  for _, v in ipairs(Trove.bird_data) do
    table.insert(bird_names, v.english_name)
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
    id = "cycle_views",
    name = "Cycle Views",
    behavior = "toggle",
    default = 1
  }

  params:add {
    type = "binary",
    id = "cycle_species",
    name = "Cycle Species",
    behavior = "toggle",
    default = 1
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
    name = "Time Per Slice",
    controlspec = specs.TIME,
    action = function(value)
      update_metro.time = value / Sequencer.STEPS_PER_SLICE
    end
  }
  params:hide("time")

  -- Params
  Oystercatcher.add_chord_params()
  Oystercatcher.add_perc_params()
  Oystercatcher.add_fx_params()
  params:bang()

  -- Start metros
  Sequencer.startup()
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
    screen.level(3)
    screen.move(2, 16)
    screen.text(Trove.get_bird(params:get("species")).latin_name)
    screen.move(126, 7)
    screen.text_right(slice.year .. " " .. slice.week)
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
