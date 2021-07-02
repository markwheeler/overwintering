local Sequencer = {}

local MusicUtil = require "musicutil"
local SonicDefs = include("lib/sonic_defs")

Sequencer.STEPS_PER_SLICE = 96

Sequencer.screen_dirty_callback = function() end
Sequencer.slice_index = 1
Sequencer.step_index = Sequencer.STEPS_PER_SLICE
Sequencer.triggers = {}
Sequencer.num_active_triggers = 0

local Trove = {}
local sonic_def = {}
local bird_index = 1
local num_slices = 0
local chord_notes = {}
local perc_notes_this_slice = {}
local perc_steps_this_slice = 0

local TRIG_RANGE = 3 -- LatLong Degrees
local TRIG_COLS = 6
local TRIG_ROWS = 3
local trigger_positions = {}


local function generate_triggers(bird_index)

  local bird = Trove.get_bird(bird_index)

  Sequencer.triggers = {}
  local trig_x_spacing = (bird.max_x - bird.min_x) / (TRIG_COLS + 1)
  local trig_y_spacing = (bird.max_y - bird.min_y) / (TRIG_ROWS + 1)

  local min_distance, max_distance = 999999, 0

  for c = 1, TRIG_COLS do
    for r = 1, TRIG_ROWS do

      local trig = {}
      trig.active = false
      trig.x = c * trig_x_spacing + bird.min_x
      trig.y = r * trig_y_spacing + bird.min_y
      trig.x_norm, trig.y_norm = Trove.normalize_point(trig.x, trig.y, bird.x_offset, bird.y_offset, bird.scale)
      trig.x_grid_norm = util.linlin(1, TRIG_COLS, 0, 1, c)
      trig.y_grid_norm = util.linlin(1, TRIG_ROWS, 1, 0, r)
      trig.screen_x = util.round(trig.x_norm * 128)
      trig.screen_y = util.round((1 - trig.y_norm) * 64)

      -- Calculate distance from perc_start
      local x_diff, y_diff = math.abs(trig.x_norm - sonic_def.perc_start_x), math.abs((1 - trig.y_norm) * 0.5 - sonic_def.perc_start_y)
      trig.distance_from_root = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
      if trig.distance_from_root < min_distance then min_distance = trig.distance_from_root end
      if trig.distance_from_root > max_distance then max_distance = trig.distance_from_root end

      table.insert(Sequencer.triggers, trig)

    end
  end

  -- Normalize distances
  for _, t in ipairs(Sequencer.triggers) do
    t.distance_from_root  = util.linlin(min_distance, max_distance, 0, 1, t.distance_from_root)
  end

end

local function update_triggers()

  -- Sort to expand/contract
  local week = Trove.get_slice(bird_index, Sequencer.slice_index).week
  table.sort(Sequencer.triggers, function(a, b)
    if week >= sonic_def.contract_range[1] and week <= sonic_def.contract_range[2] then
      return a.distance_from_root > b.distance_from_root
    else
      return a.distance_from_root < b.distance_from_root
    end
  end)

  -- TODO Perf test
  Sequencer.num_active_triggers = 0
  for _, t in ipairs(Sequencer.triggers) do
    t.active = false
    t.played = false
    for _, p in ipairs(Trove.get_slice(params:get("species"), Sequencer.slice_index).points) do
      if p.x < t.x + TRIG_RANGE and p.x > t.x - TRIG_RANGE and p.y > t.y - TRIG_RANGE and p.y < t.y + TRIG_RANGE then
        t.active = true
        Sequencer.num_active_triggers = Sequencer.num_active_triggers + 1
        break
      end
    end
  end
end

local function play_chord()

  chord_notes = {}
  local osc_mods = {}
  for i = 1, Trove.MAX_NUM_CLUSTERS do osc_mods[i] = 0 end

  local clusters = Trove.get_slice(bird_index, Sequencer.slice_index).clusters
  local current_x, current_y
  local prev_x = sonic_def.chord_start_x
  local prev_y = sonic_def.chord_start_y

  for i = 1, #clusters do
    current_x, current_y = clusters[i].centroid.x_norm, clusters[i].centroid.y_norm * 0.5

    local x_diff, y_diff = math.abs(current_x - prev_x), math.abs(current_y - prev_y)
    local distance = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
    local interval = math.floor(util.linlin(0, 1, 0, 36, distance))

    if i == 1 then
      for n = 1, Trove.MAX_NUM_CLUSTERS do
        chord_notes[n] = sonic_def.musical_scale[1] + interval -- Default all notes to first note of chord (leftover voices will therefore unison on root)
      end
    else
      chord_notes[i] = chord_notes[i - 1] + interval
    end
    osc_mods[i] = clusters[i].num_points_norm

    prev_x, prev_y = current_x, current_y
  end
  
  chord_notes = MusicUtil.snap_notes_to_array(chord_notes, sonic_def.musical_scale)

  -- Iterate the scale and remove any intervals of < 3 ST
  for i = 2, #chord_notes do
    if chord_notes[i] - chord_notes[i - 1] < 3 then
      chord_notes[i] = chord_notes[i - 1] - 12
    end
  end

  print("--- chordOn")
  for i = 1, #chord_notes do
    print(chord_notes[i], MusicUtil.note_num_to_name(chord_notes[i], true), util.round(osc_mods[i], 0.01))
  end
  print("---")

  local note_freqs = MusicUtil.note_nums_to_freqs(chord_notes)

  engine.chordOn(
    math.floor(Sequencer.slice_index), -- voiceId
    note_freqs[1], note_freqs[2], note_freqs[3], note_freqs[4], -- freqs
    osc_mods[1], osc_mods[2], osc_mods[3], osc_mods[4] -- oscMods
  )

end

local function update_chord_params()

  local slice_progress = Sequencer.step_index / Sequencer.STEPS_PER_SLICE
  local dyn_params = sonic_def.dynamic_params

  -- Area to wave shape
  params:set(
    "chord_osc_wave_shape",
    util.linlin(0, 1, dyn_params.chord_osc_wave_shape_low, dyn_params.chord_osc_wave_shape_high, Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "area_norm"))
  )
 
  -- Mass to LP filter cutoff
  params:set(
    "chord_lp_filter_cutoff",
    util.linlin(0, 1, dyn_params.chord_lp_filter_cutoff_low,dyn_params.chord_lp_filter_cutoff_high, Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "num_points_norm"))
  )

  -- Density to noise level
  params:set(
    "chord_noise_level",
    util.linlin(0, 1, dyn_params.chord_noise_level_low, dyn_params.chord_noise_level_high, Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "density_norm"))
  )

 -- TODO could use num_points per cluster here if added support to the engine for individual osc shapes or ring mod per osc or something? Or even just amp per osc?

end

local function generate_perc_notes()

  if Sequencer.num_active_triggers < 8 then
    perc_steps_this_slice = 8
  elseif Sequencer.num_active_triggers < 12 then
    perc_steps_this_slice = 12
  elseif Sequencer.num_active_triggers < 16 then
    perc_steps_this_slice = 16
  elseif Sequencer.num_active_triggers < 32 then
    perc_steps_this_slice = 32
  end

  -- Add the perc notes for this slice
  perc_notes_this_slice = {}
  for k, t in ipairs(Sequencer.triggers) do
    if t.active then
      table.insert(perc_notes_this_slice, k)
    end
  end

  -- Insert rests randomly
  -- while #perc_notes_this_slice < perc_steps_this_slice do
  --   table.insert(perc_notes_this_slice, math.random(#perc_notes_this_slice), 0)
  -- end

  -- Insert rests at end of slice
  while #perc_notes_this_slice < perc_steps_this_slice do
    table.insert(perc_notes_this_slice, 0)
  end

  print("---- perc_notes_this_slice")
  tab.print(perc_notes_this_slice)
  print("----")

end

local function play_perc(index)

  local trigger_index = perc_notes_this_slice[index]

  if trigger_index > 0 then

    -- Trigger distance from perc_start to note
    local note_num = util.linlin(0, 1, chord_notes[1] + 12, chord_notes[1] + 24, Sequencer.triggers[trigger_index].distance_from_root)
    note_num = MusicUtil.snap_note_to_array(note_num, sonic_def.musical_scale)
    print(util.round(Sequencer.triggers[trigger_index].distance_from_root, 0.1), note_num, MusicUtil.note_num_to_name(note_num, true))

    local dyn_params = sonic_def.dynamic_params

    -- Num triggers to env_release, delay_send and lp_filter_cutoff
    local num_triggers_norm = Sequencer.num_active_triggers / (TRIG_COLS * TRIG_ROWS)
    params:set("perc_env_release", util.linlin(0, 1, dyn_params.perc_env_release_low, dyn_params.perc_env_release_high, num_triggers_norm))
    params:set("perc_delay_send", util.linlin(0, 1, dyn_params.perc_delay_send_high, dyn_params.perc_delay_send_low, num_triggers_norm))
    params:set("perc_lp_filter_cutoff", util.linlin(0, 1, dyn_params.perc_lp_filter_cutoff_low, dyn_params.perc_lp_filter_cutoff_high, num_triggers_norm))

    -- Trig x position to panning
    params:set("perc_panning", util.linlin(0, 1, dyn_params.perc_panning_low, dyn_params.perc_panning_high, Sequencer.triggers[trigger_index].x_grid_norm))

    engine.percOn(
      math.floor(trigger_index), -- voiceId
      MusicUtil.note_num_to_freq(note_num), -- freq
      params:get("perc_detune_variance"),
      util.linlin(0, 1, 0.4, 1, math.random()), -- vel
      params:get("perc_amp"),
      params:get("perc_amp_mod_lfo"),
      params:get("perc_panning"),
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

    Sequencer.triggers[trigger_index].played = true

  end

end


-- Public functions

function Sequencer.update()

  if params:get("play") == 1 then
    Sequencer.step_index = Sequencer.step_index + 1
    if Sequencer.step_index > Sequencer.STEPS_PER_SLICE then
      Sequencer.step_index = 1
      Sequencer.slice_index = Sequencer.slice_index + 1
      if Sequencer.slice_index > num_slices then Sequencer.slice_index = 1 end
    end
  end

  update_chord_params()

  if Sequencer.step_index == 1 then
    play_chord()
    update_triggers()
    generate_perc_notes()
  end

  -- Play perc (passes index of perc step)
  if Sequencer.num_active_triggers > 0 and (Sequencer.step_index - 1) % (Sequencer.STEPS_PER_SLICE / perc_steps_this_slice) == 0 then
    local perc_index = math.floor(((Sequencer.step_index - 1) / Sequencer.STEPS_PER_SLICE) * perc_steps_this_slice + 1)
    -- perc_index = util.wrap(perc_index, 1, #perc_notes_this_slice) -- Required when not filling out the slices with rests
    play_perc(perc_index)
  end

  Sequencer.screen_dirty_callback()

end

function Sequencer.bird_changed(index)

  -- Store info
  bird_index = index
  sonic_def = SonicDefs[Trove.get_bird(bird_index).id]
  num_slices = Trove.get_bird(bird_index).num_slices

  -- Set state
  Sequencer.slice_index = num_slices
  Sequencer.step_index = Sequencer.STEPS_PER_SLICE

  -- Triggers
  generate_triggers(bird_index)

  -- Set engine params
  for k, v in pairs(sonic_def.params) do
    params:set(k, v)
  end

end

function Sequencer.init(trove)
  Trove = trove
end

return Sequencer
