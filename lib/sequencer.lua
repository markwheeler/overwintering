local Sequencer = {}

local MusicUtil = require "musicutil"
local SonicDefs = include("lib/sonic_defs")

Sequencer.STEPS_PER_SLICE = 64

Sequencer.screen_dirty_callback = function() end
Sequencer.slice_index = 1
Sequencer.step_index = Sequencer.STEPS_PER_SLICE
Sequencer.triggers = {}
Sequencer.num_active_triggers = 0

local Trove = {}
local sonic_def = {}
local bird_index = 1
local num_slices = 0
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

  for c = 1, TRIG_COLS do
    for r = 1, TRIG_ROWS do

      local trig = {}
      trig.active = false
      trig.x = c * trig_x_spacing + bird.min_x
      trig.y = r * trig_y_spacing + bird.min_y
      trig.screen_x, trig.screen_y = Trove.normalize_point(trig.x, trig.y, bird.x_offset, bird.y_offset, bird.scale)
      trig.screen_x = util.round(trig.screen_x * 128)
      trig.screen_y = util.round((1 - trig.screen_y) * 64)
      table.insert(Sequencer.triggers, trig)

    end
  end
end

local function update_triggers()
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

  local notes = {}
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
        notes[n] = sonic_def.musical_scale[1] + interval -- Default all notes to first note of chord (leftover voices will therefore unison on root)
      end
    else
      notes[i] = notes[i - 1] + interval
    end
    osc_mods[i] = clusters[i].num_points_norm

    prev_x, prev_y = current_x, current_y
  end
  
  notes = MusicUtil.snap_notes_to_array(notes, sonic_def.musical_scale)

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

  -- Insert pauses randomly
  while #perc_notes_this_slice < perc_steps_this_slice do
    table.insert(perc_notes_this_slice, math.random(#perc_notes_this_slice), 0)
  end

  print("---- perc_notes_this_slice")
  tab.print(perc_notes_this_slice)
  print("----")

end

local function play_perc(index)

  local trigger_index = perc_notes_this_slice[index]

  if trigger_index > 0 then

    -- Play note
    print("percOn", index, trigger_index)

    -- TODO refine logic
    -- Maybe use trigger position etc via trigger_index
    local note_num = math.random(sonic_def.musical_scale[1] + 36,sonic_def.musical_scale[1] + 48)
    note_num = MusicUtil.snap_note_to_array(note_num, sonic_def.musical_scale)
    
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
    play_perc(math.floor(((Sequencer.step_index - 1) / Sequencer.STEPS_PER_SLICE) * perc_steps_this_slice + 1))
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
