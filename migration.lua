-- Migration
-- 1.0.0 @markeats @giovannilami
--
-- WIP
--

local ControlSpec = require "controlspec"
local MusicUtil = require "musicutil"

local Trove = include("lib/trove")
local SonicDefs = include("lib/sonic_defs")
local Oystercatcher = include("lib/oystercatcher_engine")

engine.name = "Oystercatcher"

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local update_metro

local slice_index = 1
local bird_data = {}

local STEPS_PER_SLICE = 64
local step_index = STEPS_PER_SLICE
local perc_notes_this_slice = {}
local perc_steps_this_slice = 8

local TRIG_RANGE = 3 -- LatLong Degrees
local TRIG_COLS = 6
local TRIG_ROWS = 3
local trigger_positions = {}
local triggers = {}
local num_active_triggers = 0

local NUM_VIEW_MODES = 4
local view_mode = 1-- Map, Stats, Bounds, Triggers

local specs = {}
specs.TIME = ControlSpec.new(1, 12, "lin", 0, 8, "s")


-- Functions

local function current_bird()
  return Trove.bird_data[params:get("species")]
end

local function current_slice()
  return current_bird().slices[slice_index]
end

local function next_slice()
  local index = slice_index + 1
  index = util.wrap(index, 1, current_bird().num_slices)
  return current_bird().slices[index]
end

local function interp_slice_value(value_name)
  return util.linlin(0, 1, current_slice()[value_name], next_slice()[value_name], step_index / STEPS_PER_SLICE)
end

local function current_sonic_def()
  return SonicDefs[current_bird().id]
end

local function bird_changed()
  slice_index = current_bird().num_slices
  step_index = STEPS_PER_SLICE

  -- Generate trigs
  triggers = {}
  local trig_x_spacing = (current_bird().max_x - current_bird().min_x) / (TRIG_COLS + 1)
  local trig_y_spacing = (current_bird().max_y - current_bird().min_y) / (TRIG_ROWS + 1)
  
  for c = 1, TRIG_COLS do
    for r = 1, TRIG_ROWS do

      local trig = {}
      trig.active = false
      trig.x = c * trig_x_spacing + current_bird().min_x
      trig.y = r * trig_y_spacing + current_bird().min_y
      trig.screen_x, trig.screen_y = Trove.normalize_point(trig.x, trig.y, current_bird().x_offset, current_bird().y_offset, current_bird().scale)
      trig.screen_x = util.round(trig.screen_x * 128)
      trig.screen_y = util.round((1 - trig.screen_y) * 64)
      table.insert(triggers, trig)

    end
  end

  -- Set engine params
  for k, v in pairs(current_sonic_def().params) do
    params:set(k, v)
  end

end

local function play_chord()

  local notes = {}
  local osc_mods = {}
  for i = 1, Trove.MAX_NUM_CLUSTERS do osc_mods[i] = 0 end

  local clusters = current_slice().clusters
  local current_x, current_y
  local prev_x = current_sonic_def().chord_start_x
  local prev_y = current_sonic_def().chord_start_y

  for i = 1, #clusters do
    current_x, current_y = clusters[i].centroid.x_norm, clusters[i].centroid.y_norm * 0.5

    local x_diff, y_diff = math.abs(current_x - prev_x), math.abs(current_y - prev_y)
    local distance = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
    local interval = math.floor(util.linlin(0, 1, 0, 36, distance))

    if i == 1 then
      for n = 1, Trove.MAX_NUM_CLUSTERS do
        notes[n] = current_sonic_def().musical_scale[1] + interval -- Default all notes to first note of chord (leftover voices will therefore unison on root)
      end
    else
      notes[i] = notes[i - 1] + interval
    end
    osc_mods[i] = clusters[i].num_points_norm

    prev_x, prev_y = current_x, current_y
  end
  
  notes = MusicUtil.snap_notes_to_array(notes, current_sonic_def().musical_scale)

  -- Iterate the scale and remove any intervals of < 3 ST
  for i = 2, #notes do
    if notes[i] - notes[i - 1] < 3 then
      notes[i] = notes[i - 1] - 12
    end
  end

  print("--- chordOn")
  for i = 1, #notes do
    print(notes[i], MusicUtil.note_num_to_name(notes[i], true), util.round(osc_mods[i], 0.01))
  end
  print("---")

  local note_freqs = MusicUtil.note_nums_to_freqs(notes)

  engine.chordOn(
    math.floor(slice_index), -- voiceId
    note_freqs[1], note_freqs[2], note_freqs[3], note_freqs[4], -- freqs
    osc_mods[1], osc_mods[2], osc_mods[3], osc_mods[4] -- oscMods
  )

end

local function update_chord_params()

  -- Area to wave shape
  params:set(
   "chord_osc_wave_shape",
   util.linlin(0, 1, current_sonic_def().dynamic_params.chord_osc_wave_shape_low, current_sonic_def().dynamic_params.chord_osc_wave_shape_high, interp_slice_value("area_norm"))
 )
 
 -- Mass to LP filter cutoff
 params:set(
   "chord_lp_filter_cutoff",
   util.linlin(0, 1, current_sonic_def().dynamic_params.chord_lp_filter_cutoff_low, current_sonic_def().dynamic_params.chord_lp_filter_cutoff_high, interp_slice_value("num_points_norm"))
 )

 -- Density to noise level
 params:set(
   "chord_noise_level",
   util.linlin(0, 1, current_sonic_def().dynamic_params.chord_noise_level_low, current_sonic_def().dynamic_params.chord_noise_level_high, interp_slice_value("density_norm"))
 )

 -- TODO could use num_points per cluster here if added support to the engine for individual osc shapes or ring mod per osc or something? Or even just amp per osc?

end


local function detect_triggers()
  -- TODO Perf test
  num_active_triggers = 0
  for _, t in ipairs(triggers) do
    t.active = false
    t.played = false
    for _, p in ipairs(current_slice().points) do
      if p.x < t.x + TRIG_RANGE and p.x > t.x - TRIG_RANGE and p.y > t.y - TRIG_RANGE and p.y < t.y + TRIG_RANGE then
        t.active = true
        num_active_triggers = num_active_triggers + 1
        break
      end
    end
  end
end

local function generate_perc_notes()

  if num_active_triggers < 8 then
    perc_steps_this_slice = 8
  elseif num_active_triggers < 16 then
    perc_steps_this_slice = 16
  elseif num_active_triggers < 32 then
    perc_steps_this_slice = 32
  end

  -- Add the perc notes for this slice
  perc_notes_this_slice = {}
  for k, t in ipairs(triggers) do
    if t.active then
      table.insert(perc_notes_this_slice, k)
    end
  end

  -- Insert pauses randomly
  while #perc_notes_this_slice < perc_steps_this_slice do
    table.insert(perc_notes_this_slice, math.random(#perc_notes_this_slice), 0)
  end

  print("---- perc_notes_this_slice")
  tab.print(perc_notes_this_slice)
  print("----")

end

local function play_perc(index)

  trigger_index = perc_notes_this_slice[index]

  if trigger_index > 0 then

    -- Play note
    print("percOn", index, trigger_index)

    -- TODO refine logic
    -- Maybe use trigger position etc via trigger_index
    local note_num = math.random(current_sonic_def().musical_scale[1] + 24, current_sonic_def().musical_scale[1] + 36)
    note_num = MusicUtil.snap_note_to_array(note_num, current_sonic_def().musical_scale)
    
    engine.percOn(
      math.floor(trigger_index), -- voiceId
      MusicUtil.note_num_to_freq(note_num), -- freq
      params:get("perc_detune_variance"),
      util.linlin(0, 1, 0.4, 1, math.random()), -- vel
      params:get("perc_amp"),
      params:get("perc_amp_mod_lfo"),
      params:get("perc_freq_mod_env"),
      params:get("perc_freq_mod_lfo"),
      params:get("perc_osc_wave_shape"),
      params:get("perc_osc_wave_shape_mod_env"),
      params:get("perc_osc_wave_shape_mod_lfo"),
      params:get("perc_osc_level"),
      params:get("perc_noise_level"),
      params:get("perc_crackle_level"),
      params:get("perc_lp_filter_cutoff"),
      params:get("perc_lp_filter_cutoff_mod_env"),
      params:get("perc_lp_filter_cutoff_mod_lfo"),
      params:get("perc_lp_filter_resonance"),
      params:get("perc_env_attack"),
      params:get("perc_env_release"),
      params:get("perc_lfo_freq"),
      params:get("perc_chorus_send"),
      params:get("perc_delay_send")
    )

    triggers[trigger_index].played = true

  end

end


-- Metro callbacks

local function update()

  if params:get("play") == 1 then
    step_index = step_index + 1
    if step_index > STEPS_PER_SLICE then
      step_index = 1
      slice_index = slice_index + 1
      if slice_index > current_bird().num_slices then slice_index = 1 end
    end
  end

  update_chord_params()

  if step_index == 1 then
    play_chord()
    detect_triggers()
    generate_perc_notes()
  end

  -- Play perc (passes index of perc step)
  if (step_index - 1) % (STEPS_PER_SLICE / perc_steps_this_slice) == 0 then
    play_perc(math.floor(((step_index - 1) / STEPS_PER_SLICE) * perc_steps_this_slice + 1))
  end
  
  screen_dirty = true

end

local function screen_update()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
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

  -- Init
  update_metro = metro.init(update)

  -- Load data

  Trove.load_folder(norns.state.path .. "data/")

  local bird_names = {}

  if #Trove.bird_data == 0 then
    table.insert(bird_names, "No bird data")
  end

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
      update_metro.time = value / STEPS_PER_SLICE
    end
  }

  -- Params
  Oystercatcher.add_chord_params()
  Oystercatcher.add_perc_params()
  Oystercatcher.add_fx_params()
  params:bang()

  -- Start routines
  metro.init(screen_update, 1 / SCREEN_FRAMERATE):start()
  update_metro:start()

end


local function draw_map(points, level)
  screen.level(level)
  for _, p in ipairs(current_slice().points) do
    screen.rect(p.x_norm * 128 - 0.5, 64 - p.y_norm * 64 - 0.5, 1, 1)
    screen.fill()
  end
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
    screen.move(2, 21)
    screen.text("Area")
    screen.fill()
    screen.rect(40, 18, interp_slice_value("area_norm") * 76,  2)
    screen.fill()

    -- Mass
    screen.move(2, 30)
    screen.text("Mass")
    screen.fill()
    screen.rect(40, 27, interp_slice_value("num_points_norm") * 76,  2)
    screen.fill()

    -- Density
    screen.move(2, 39)
    screen.text("Density")
    screen.fill()
    screen.rect(40, 36, interp_slice_value("density_norm") * 76,  2)
    screen.fill()

  -- Cluster view
  elseif view_mode == 3 then

    -- Slice bounds
    screen.level(3)
    screen.rect(math.floor(current_slice().min_x_norm * 128) - 0.5, 64 - math.floor(current_slice().max_y_norm * 64) - 0.5, math.ceil((current_slice().max_x_norm - current_slice().min_x_norm) * 128) + 1,  math.ceil((current_slice().max_y_norm - current_slice().min_y_norm) * 64) + 1)
    screen.stroke()

    -- Cluster centroids
    screen.level(15)
    for _, c in ipairs(current_slice().clusters) do
      screen.rect(util.round(c.centroid.x_norm * 128) - 2.5, util.round(64 - c.centroid.y_norm * 64) - 2.5, 5, 5)
      screen.stroke()
      -- screen.move(util.round(c.centroid.x_norm * 128) + 4, util.round(64 - c.centroid.y_norm * 64) + 2)
      -- screen.text(c.num_points_norm)
      screen.fill()
    end

  -- Triggers view
  elseif view_mode == 4 then
    
    screen.level(15)
    for _, t in ipairs(triggers) do
      if t.active then
        screen.rect(t.screen_x - 2.5, t.screen_y - 2.5, 5, 5)
        screen.stroke()
      end
      if t.played or not t.active then
        screen.rect(t.screen_x - 1, t.screen_y - 1, 2, 2)
        screen.fill()
      end

    end

  end

  -- Progress
  screen.level(3)
  screen.rect(0, 63, util.linlin(1, current_bird().num_slices, 0, 128, slice_index + step_index / STEPS_PER_SLICE), 1)
  screen.fill()

  screen.update()
end
