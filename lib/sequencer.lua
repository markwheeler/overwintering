local Sequencer = {}

local MusicUtil = require "musicutil"
local SonicDefs = include("lib/sonic_defs")

Sequencer.STEPS_PER_SLICE = 96

Sequencer.screen_dirty_callback = function() end
Sequencer.slice_changed_callback = function() end
Sequencer.slice_index = 1
Sequencer.step_index = 1
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
local TRIG_DISPLAY_TIME = 28 -- In steps
local trigger_positions = {}


-- Triggers

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
      trig.display_timer = 0
      trig.x = c * trig_x_spacing + bird.min_x
      trig.y = r * trig_y_spacing + bird.min_y
      trig.x_norm, trig.y_norm = Trove.normalize_point(trig.x, trig.y, bird.x_offset, bird.y_offset, bird.scale)
      trig.x_grid_norm = util.linlin(1, TRIG_COLS, 0, 1, c)
      trig.y_grid_norm = util.linlin(1, TRIG_ROWS, 1, 0, r)
      trig.screen_x = util.round(trig.x_norm * 126 + 1)
      trig.screen_y = util.round((1 - trig.y_norm) * 62 + 1)
      trig.mod_a = util.linlin(1, TRIG_COLS * TRIG_ROWS, 0, 1, (r - 1 ) * TRIG_COLS + c)
      trig.mod_b = util.linlin(1, TRIG_COLS * TRIG_ROWS, 1, 0, (c - 1 ) * TRIG_ROWS + r)

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
    t.display_timer = 0
    for _, p in ipairs(Trove.get_slice(params:get("species"), Sequencer.slice_index).points) do
      if p.x < t.x + TRIG_RANGE and p.x > t.x - TRIG_RANGE and p.y > t.y - TRIG_RANGE and p.y < t.y + TRIG_RANGE then
        t.active = true
        Sequencer.num_active_triggers = Sequencer.num_active_triggers + 1
        break
      end
    end
  end
end

local function update_trig_display()
  for _, t in ipairs(Sequencer.triggers) do
    if t.display_timer > 0 then
      t.display_timer = t.display_timer - 1 / TRIG_DISPLAY_TIME
    end
  end
end


-- Notes

local function play_chord()

  chord_notes = {}
  local osc_mods = {}
  for i = 1, Trove.MAX_NUM_CLUSTERS do osc_mods[i] = 0 end

  local clusters = Trove.get_slice(bird_index, Sequencer.slice_index).clusters
  local current_x, current_y
  local prev_x = sonic_def.chord_start_x
  local prev_y = sonic_def.chord_start_y

  local num_clusters = #clusters
  if num_clusters > 0 then

    for i = 1, num_clusters do
      current_x, current_y = clusters[i].x, clusters[i].y * 0.5

      local x_diff, y_diff = math.abs(current_x - prev_x), math.abs(current_y - prev_y)
      local distance = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
      local interval = math.floor(util.linlin(0, 1, 0, 38, distance))

      -- TODO is this the right value?
      if interval > 16 then print("LARGE INTERVAL ALERT -------------------------------->", interval) end
      interval = math.min(interval, 22)

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

    print("--- chordOn", Sequencer.slice_index)
    for i = 1, #chord_notes do
      print(chord_notes[i], MusicUtil.note_num_to_name(chord_notes[i], true), util.round(osc_mods[i], 0.01))
    end
    print("---")

    local note_freqs = MusicUtil.note_nums_to_freqs(chord_notes)

    engine.chordOn(
      Sequencer.slice_index, -- voiceId
      note_freqs[1], note_freqs[2], note_freqs[3], note_freqs[4], -- freqs
      osc_mods[1], osc_mods[2], osc_mods[3], osc_mods[4] -- oscMods
    )
  end

end

local function generate_perc_notes()

  if Sequencer.num_active_triggers < 12 then
    perc_steps_this_slice = 12
  else
    perc_steps_this_slice = 24
  end

  -- if Sequencer.num_active_triggers < 8 then
  --   perc_steps_this_slice = 8
  -- elseif Sequencer.num_active_triggers < 12 then
  --   perc_steps_this_slice = 12
  -- elseif Sequencer.num_active_triggers < 16 then
  --   perc_steps_this_slice = 16
  -- else
  --   perc_steps_this_slice = 32
  -- end

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
  -- while #perc_notes_this_slice < perc_steps_this_slice do
  --   table.insert(perc_notes_this_slice, 0)
  -- end

  -- print("---- perc_notes_this_slice")
  -- tab.print(perc_notes_this_slice)
  -- print("----")

end

local function play_perc(index)

  local trigger_index = perc_notes_this_slice[index]

  if trigger_index > 0 then

    local trigger = Sequencer.triggers[trigger_index]

    -- Trigger distance from perc_start to note
    local note_range = {chord_notes[1], chord_notes[1] + 40}
    local note_num = util.linlin(0, 1, note_range[1], note_range[2], trigger.distance_from_root)
    note_num = MusicUtil.snap_note_to_array(note_num, sonic_def.musical_scale)
    local sub_note_num = note_num - 5
    -- print(util.round(trigger.distance_from_root, 0.1), note_num, MusicUtil.note_num_to_name(note_num, true))

    local slice_progress = Sequencer.step_index / Sequencer.STEPS_PER_SLICE
    local dyn_params = sonic_def.dynamic_params

    -- Trigger mod_b to osc level, crackle level and filter resonance
    params:set("perc_osc_level", util.linlin(0, 1, dyn_params.perc_osc_level_high, dyn_params.perc_osc_level_low, trigger.mod_a))
    params:set("perc_crackle_level", util.linlin(0, 1, dyn_params.perc_crackle_level_low, dyn_params.perc_crackle_level_high, trigger.mod_a))
    params:set("perc_lp_filter_resonance", util.linlin(0, 1, dyn_params.perc_lp_filter_resonance_high, dyn_params.perc_lp_filter_resonance_low, trigger.mod_a))
    
    -- Trigger mod_b to filter cutoff
    params:set("perc_lp_filter_cutoff", util.linexp(0, 1, dyn_params.perc_lp_filter_cutoff_low, dyn_params.perc_lp_filter_cutoff_high, trigger.mod_b))

    -- Density to LFO freq
    params:set("perc_lfo_freq", util.linexp(0, 1, dyn_params.perc_lfo_freq_low, dyn_params.perc_lfo_freq_high, Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "density_norm")))

    -- Num triggers to env_release, delay_send and lp_filter_cutoff
    local num_triggers_norm = Sequencer.num_active_triggers / (TRIG_COLS * TRIG_ROWS)
    params:set("perc_env_release", util.linlin(0, 1, dyn_params.perc_env_release_low, dyn_params.perc_env_release_high, num_triggers_norm))
    params:set("perc_delay_send", util.linlin(0, 1, dyn_params.perc_delay_send_high, dyn_params.perc_delay_send_low, num_triggers_norm))

    -- Trig x position to panning
    params:set("perc_panning", util.linlin(0, 1, dyn_params.perc_panning_low, dyn_params.perc_panning_high, trigger.x_grid_norm))

    -- Trig y position to sub osc level
    params:set("perc_sub_osc_level", util.linlin(0, 1, dyn_params.perc_sub_osc_level_low, dyn_params.perc_sub_osc_level_high, trigger.y_grid_norm))

    -- Velocity
    local velocity = util.linlin(note_range[1], note_range[2], 0.8, 0.5, note_num)
    -- local velocity = util.linlin(0, 1, 0.65, 0.8, params:get("perc_osc_level"))
    velocity = velocity + math.random() * 0.2

    engine.percOn(
      trigger_index, -- voiceId
      MusicUtil.note_num_to_freq(note_num), -- freq0
      MusicUtil.note_num_to_freq(sub_note_num), -- freq1
      params:get("perc_detune_variance"),
      velocity, -- vel
      params:get("perc_amp"),
      params:get("perc_amp_mod_lfo"),
      params:get("perc_panning"),
      params:get("perc_freq_mod_env"),
      params:get("perc_freq_mod_lfo"),
      params:get("perc_osc_wave_shape"),
      params:get("perc_osc_wave_shape_mod_env"),
      params:get("perc_osc_wave_shape_mod_lfo"),
      params:get("perc_osc_level"),
      params:get("perc_sub_osc_level"),
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

    trigger.display_timer = 1

  end

end


-- Advance

local function step_changed()

  -- Update chord and FX params

  local slice_progress = Sequencer.step_index / Sequencer.STEPS_PER_SLICE
  local dyn_params = sonic_def.dynamic_params

  -- Area to wave shape and amp mod LFO
  local area = Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "area_norm")
  params:set(
    "chord_osc_wave_shape",
    util.linlin(0, 1, dyn_params.chord_osc_wave_shape_low, dyn_params.chord_osc_wave_shape_high, area)
  )
  params:set(
    "chord_amp_mod_lfo",
    util.linlin(0, 1, dyn_params.chord_amp_mod_lfo_low, dyn_params.chord_amp_mod_lfo_high, area)
  )
 
  -- Mass to LP filter cutoff and delay feedback
  local mass = Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "num_points_norm")
  params:set(
    "chord_lp_filter_cutoff",
    util.linlin(0, 1, dyn_params.chord_lp_filter_cutoff_low,dyn_params.chord_lp_filter_cutoff_high, mass)
  )
  params:set(
    "fx_delay_feedback",
    util.linlin(0, 1, dyn_params.fx_delay_feedback_high, dyn_params.fx_delay_feedback_low, mass)
  )

  -- Density to noise level
  local density = Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "density_norm")
  params:set(
    "chord_noise_level",
    util.linlin(0, 1, dyn_params.chord_noise_level_low, dyn_params.chord_noise_level_high, density)
  )

  -- Lower bound to LFO freq
  local lower_bound = 1 - Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "min_y_norm")
  params:set(
    "chord_lfo_freq",
    util.linlin(0, 1, dyn_params.chord_lfo_freq_low, dyn_params.chord_lfo_freq_high, lower_bound)
  )

 -- TODO could use num_points per cluster here if added support to the engine for individual osc shapes or ring mod per osc or something? Or even just amp per osc?

  -- Play perc (passes index of perc step)

  if Sequencer.num_active_triggers > 0 and (Sequencer.step_index - 1) % (Sequencer.STEPS_PER_SLICE / perc_steps_this_slice) == 0 then
    local perc_index = math.floor(((Sequencer.step_index - 1) / Sequencer.STEPS_PER_SLICE) * perc_steps_this_slice + 1)
    perc_index = util.wrap(perc_index, 1, #perc_notes_this_slice) -- Required when not filling out the slices with rests
    play_perc(perc_index)
  end

end

local function slice_changed()
  play_chord()
  -- update_triggers() -- TODO
  generate_perc_notes()
  Sequencer.slice_changed_callback()
end


-- Public functions

function Sequencer.bird_changed(index)

  -- Store info
  bird_index = index
  sonic_def = SonicDefs[Trove.get_bird(bird_index).species_id]
  if not sonic_def then
    local random_sonic_def = next(SonicDefs)
    print("No sonic def found. Using " .. random_sonic_def)
    sonic_def = SonicDefs[random_sonic_def]
  end
  num_slices = Trove.get_bird(bird_index).num_slices

  -- Set state
  Sequencer.slice_index = 1
  Sequencer.step_index = 1

  -- Triggers
  -- generate_triggers(bird_index) -- TODO

  -- Set engine params
  for k, v in pairs(sonic_def.params) do
    params:set(k, v)
  end

end

function Sequencer.update()

  -- Advance playback
  if params:get("play") == 1 then

    Sequencer.step_index = Sequencer.step_index + 1
    step_changed()

    if Sequencer.step_index > Sequencer.STEPS_PER_SLICE then

      Sequencer.step_index = 1
      Sequencer.slice_index = Sequencer.slice_index + 1
      if Sequencer.slice_index > num_slices then Sequencer.slice_index = 1 end

      slice_changed()
    end
  end

  update_trig_display()

  Sequencer.screen_dirty_callback()
end

function Sequencer.init(trove)
  Trove = trove
end

function Sequencer.startup()
  step_changed()
  slice_changed()
end

return Sequencer
