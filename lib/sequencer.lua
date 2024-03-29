local Sequencer = {}

local MusicUtil = require "musicutil"

Sequencer.STEPS_PER_SLICE = 96

Sequencer.screen_dirty_callback = function() end
Sequencer.slice_changed_callback = function() end
Sequencer.slice_index = 1
Sequencer.step_index = 1
Sequencer.triggers = {}
Sequencer.num_active_triggers = 0

local Trove = {}
local sonic_defs = {}
local bird_index = 1
local num_slices = 0
local chord_notes = {}
local perc_notes_this_slice = {}
local perc_steps_this_slice = 0

local TRIG_RANGE = 0.06
local TRIG_COLS = 6
local TRIG_ROWS = 3
local TRIG_DISPLAY_TIME = 28 -- In steps
local trigger_positions = {}

local fade_out = false


-- Sonic def loading

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function load_sonic_def(species_id)
  local def
  local path_prefix = script_path() .. "sonic_def_"
  local path = path_prefix .. species_id .. ".lua"
  if file_exists(path) then
    def = dofile(path)
    print("Loaded sonic def for species " .. species_id)
  else
    def = dofile(path_prefix .. "default.lua")
    print("No sonic def found for species " .. species_id .. " (using default)")
  end
  return def
end

local function load_sonic_defs(species_ids)
  sonic_defs = {}
  for _, v in ipairs(species_ids) do
    local species_id = tostring(v)
    table.insert(sonic_defs, load_sonic_def(species_id))
  end
end


-- Triggers

local function generate_triggers(bird_index)

  local bird = Trove.get_bird(bird_index)

  Sequencer.triggers = {}
  local trig_x_spacing = 1 / (TRIG_COLS + 1)
  local trig_y_spacing = 1 / (TRIG_ROWS + 1)

  local min_distance, max_distance = 999999, 0

  for c = 1, TRIG_COLS do
    for r = 1, TRIG_ROWS do

      local trig = {}
      trig.active = false
      trig.display_timer = 0
      trig.x = c * trig_x_spacing
      trig.y = r * trig_y_spacing
      trig.x_grid_norm = util.linlin(1, TRIG_COLS, 0, 1, c)
      trig.y_grid_norm = util.linlin(1, TRIG_ROWS, 1, 0, r)
      trig.screen_x = util.round(trig.x * 126 + 1)
      trig.screen_y = util.round((1 - trig.y) * 62 + 1)
      trig.mod_a = util.linlin(1, TRIG_COLS * TRIG_ROWS, 0, 1, (r - 1 ) * TRIG_COLS + c)
      trig.mod_b = util.linlin(1, TRIG_COLS * TRIG_ROWS, 1, 0, (c - 1 ) * TRIG_ROWS + r)

      -- Calculate distance from perc_start
      local x_diff, y_diff = math.abs(trig.x - sonic_defs[bird_index].perc_start_x), math.abs((1 - trig.y) * 0.5 - sonic_defs[bird_index].perc_start_y)
      trig.distance_from_root = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
      if trig.distance_from_root < min_distance then min_distance = trig.distance_from_root end
      if trig.distance_from_root > max_distance then max_distance = trig.distance_from_root end

      table.insert(Sequencer.triggers, trig)

    end
  end

  -- Normalize distance from root
  for _, t in ipairs(Sequencer.triggers) do
    t.distance_from_root = util.linlin(min_distance, max_distance, 0, 1, t.distance_from_root)
  end

end

local function update_triggers()

  -- Sort to expand/contract
  local week = Trove.get_slice(bird_index, Sequencer.slice_index).week
  table.sort(Sequencer.triggers, function(a, b)
    if (sonic_defs[bird_index].contract_range[1] < sonic_defs[bird_index].contract_range[2] and week >= sonic_defs[bird_index].contract_range[1] and week <= sonic_defs[bird_index].contract_range[2])
    or (sonic_defs[bird_index].contract_range[1] > sonic_defs[bird_index].contract_range[2] and week >= sonic_defs[bird_index].contract_range[1] or week <= sonic_defs[bird_index].contract_range[2]) then
      return a.distance_from_root > b.distance_from_root
    else
      return a.distance_from_root < b.distance_from_root
    end
  end)

  -- Activate triggers
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
  for i = 1, Trove.MAX_NUM_CLUSTERS do
    chord_notes[i] = sonic_defs[bird_index].musical_scale[1]
    osc_mods[i] = 0
  end

  local clusters = Trove.get_slice(bird_index, Sequencer.slice_index).clusters
  local current_x, current_y
  local prev_x = sonic_defs[bird_index].chord_start_x
  local prev_y = sonic_defs[bird_index].chord_start_y

  local num_clusters = #clusters
  if num_clusters > 0 then

    for i = 1, num_clusters do
      current_x, current_y = clusters[i].x, clusters[i].y * 0.5

      local x_diff, y_diff = math.abs(current_x - prev_x), math.abs(current_y - prev_y)
      local distance = math.sqrt(math.pow(x_diff, 2) + math.pow(y_diff, 2))
      local interval = math.floor(util.linlin(0, 1, 0, 38, distance))

      -- NOTE: Could tweak this value
      interval = math.min(interval, 22)

      if i == 1 then
        for n = 1, Trove.MAX_NUM_CLUSTERS do
          chord_notes[n] = sonic_defs[bird_index].musical_scale[1] + interval -- Default all notes to first note of chord (leftover voices will therefore unison on root)
        end
      else
        chord_notes[i] = chord_notes[i - 1] + interval
      end
      osc_mods[i] = math.sqrt(clusters[i].num_points_norm)

      prev_x, prev_y = current_x, current_y
    end
    
    chord_notes = MusicUtil.snap_notes_to_array(chord_notes, sonic_defs[bird_index].musical_scale)

    -- Iterate the scale and remove any intervals of < 3 ST
    for i = 2, #chord_notes do
      if chord_notes[i] - chord_notes[i - 1] < 3 then
        chord_notes[i] = chord_notes[i - 1] - 12
      end
    end

  end

  -- Min value for first note in chord to avoid silence
  osc_mods[1] = math.max(osc_mods[1], 0.1)

  local note_freqs = MusicUtil.note_nums_to_freqs(chord_notes)

  engine.chordOn(
    Sequencer.slice_index, -- voiceId
    note_freqs[1], note_freqs[2], note_freqs[3], note_freqs[4], -- freqs
    osc_mods[1], osc_mods[2], osc_mods[3], osc_mods[4] -- oscMods
  )

end

local function generate_perc_notes()

  perc_steps_this_slice = 24

  -- Add the perc notes for this slice
  perc_notes_this_slice = {}
  for k, t in ipairs(Sequencer.triggers) do
    if t.active then
      table.insert(perc_notes_this_slice, k)
    end
  end

  -- Fill out the rest of the table with rest and repeated notes
  while #perc_notes_this_slice < perc_steps_this_slice do
    if math.random() > 0.2 or #perc_notes_this_slice == 0 then
      -- Insert a rest
      table.insert(perc_notes_this_slice, math.random(math.max(#perc_notes_this_slice, 1)), 0)
    else
      -- Repeat an existing random note
      table.insert(perc_notes_this_slice, math.random(#perc_notes_this_slice), perc_notes_this_slice[math.random(#perc_notes_this_slice)])
    end
  end

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
    local note_range = {chord_notes[1], chord_notes[1] + 38}
    local note_num = util.linlin(0, 1, note_range[1], note_range[2], trigger.distance_from_root)
    note_num = MusicUtil.snap_note_to_array(note_num, sonic_defs[bird_index].musical_scale)

    -- If this is the first step then snap discordant notes to chord root, maintaining octave
    if index == 1 then
      local distance_from_chord_root = (chord_notes[1] % 12) - (note_num % 12)
      if math.abs(distance_from_chord_root) < 3 and math.abs(distance_from_chord_root) > 0 then
        -- print(" Snap!", MusicUtil.note_num_to_name(note_num, true), MusicUtil.note_num_to_name(note_num + distance_from_chord_root, true))
        note_num = note_num + distance_from_chord_root
      end
    end

    local sub_note_num = note_num - 5

    local slice_progress = Sequencer.step_index / Sequencer.STEPS_PER_SLICE
    local dyn_params = sonic_defs[bird_index].dynamic_params

    -- Trigger mod_a to osc level, crackle level and filter resonance
    params:set("perc_osc_level", util.linlin(0, 1, dyn_params.perc_osc_level_high, dyn_params.perc_osc_level_low, trigger.mod_a))
    params:set("perc_crackle_level", util.linlin(0, 1, dyn_params.perc_crackle_level_low, dyn_params.perc_crackle_level_high, trigger.mod_a))
    params:set("perc_lp_filter_resonance", util.linlin(0, 1, dyn_params.perc_lp_filter_resonance_high, dyn_params.perc_lp_filter_resonance_low, trigger.mod_a))
    
    -- Trigger mod_b to filter cutoff
    params:set("perc_lp_filter_cutoff", util.linexp(0, 1, dyn_params.perc_lp_filter_cutoff_low, dyn_params.perc_lp_filter_cutoff_high, trigger.mod_b))

    -- Density to LFO freq
    params:set("perc_lfo_freq", util.linexp(0, 1, dyn_params.perc_lfo_freq_low, dyn_params.perc_lfo_freq_high, Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "density_norm")))

    -- Num triggers (and some random) to env_release, delay_send
    local num_triggers_norm = (Sequencer.num_active_triggers / (TRIG_COLS * TRIG_ROWS) + math.random()) * 0.5
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
  local dyn_params = sonic_defs[bird_index].dynamic_params

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
 
  -- Mass to LP filter cutoff and delay feedback and decay/release/amp
  local mass = Trove.interp_slice_value(bird_index, Sequencer.slice_index, Sequencer.slice_index + 1, slice_progress, "num_points_norm")
  params:set(
    "chord_lp_filter_cutoff",
    util.linlin(0, 1, dyn_params.chord_lp_filter_cutoff_low,dyn_params.chord_lp_filter_cutoff_high, mass)
  )
  params:set(
    "fx_delay_feedback",
    util.linlin(0, 1, dyn_params.fx_delay_feedback_high, dyn_params.fx_delay_feedback_low, mass)
  )
  params:set(
    "chord_env_decay",
    util.linlin(0, 1, dyn_params.chord_env_decay_low, dyn_params.chord_env_decay_high, mass)
  )
  params:set(
    "chord_env_release",
    util.linlin(0, 1, dyn_params.chord_env_release_low, dyn_params.chord_env_release_high, mass)
  )
  params:set(
    "chord_amp",
    util.linlin(0, 1, dyn_params.chord_amp_low, dyn_params.chord_amp_high, mass)
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

  -- Play perc (passes index of perc step)
  if Sequencer.num_active_triggers > 0 and (Sequencer.step_index - 1) % (Sequencer.STEPS_PER_SLICE / perc_steps_this_slice) == 0 then
    local perc_index = math.floor(((Sequencer.step_index - 1) / Sequencer.STEPS_PER_SLICE) * perc_steps_this_slice + 1)
    perc_index = util.wrap(perc_index, 1, #perc_notes_this_slice) -- Required when not filling out the slices with rests
    play_perc(perc_index)
  end

end

local function slice_changed()
  play_chord()
  update_triggers()
  generate_perc_notes()
  Sequencer.slice_changed_callback()
end

local function fade_out_complete(bird_index)
  -- Set engine params
  for k, v in pairs(sonic_defs[bird_index].params) do
    params:set(k, v)
  end
  fade_out = false
end


-- Public functions

function Sequencer.bird_changed(index)

  -- Store info
  bird_index = index
  num_slices = Trove.get_bird(bird_index).num_slices

  -- Set state
  Sequencer.slice_index = 1
  Sequencer.step_index = 1

  -- Triggers
  generate_triggers(bird_index)

  -- Start fade out
  params:set("mixer_amp", 0)
  fade_out = true
  
end

function Sequencer.slice_delta(delta)
  Sequencer.slice_index = util.clamp(Sequencer.slice_index + delta, 1, num_slices)
end

function Sequencer.update()

  -- Advance playback
  if params:get("play") == 1 then

    Sequencer.step_index = Sequencer.step_index + 1

    if Sequencer.step_index > Sequencer.STEPS_PER_SLICE then

      Sequencer.step_index = 1
      Sequencer.slice_index = Sequencer.slice_index + 1

      -- At end of data
      if Sequencer.slice_index > num_slices then
        if params:get("cycle_species") > 0 then
          local new_species_id = params:get("species") + 1
          if new_species_id > params:get_range("species")[2] then new_species_id = 1 end
          params:set("species", new_species_id)
          Sequencer.slice_index = 1
        else
          Sequencer.slice_index = 1
        end
      end

      step_changed()
      slice_changed()

    else
      step_changed()
    end

    -- Fade out/in
    if fade_out then
      fade_out_complete(params:get("species"))
    end
    if params:get("mixer_amp") < 1 then
      params:delta("mixer_amp", 4)
    end

  else
    params:set("mixer_amp", 0)

  end

  update_trig_display()

  Sequencer.screen_dirty_callback()
end

function Sequencer.init(trove)
  Trove = trove

  -- Load sonic defs
  local species_ids = {}
  for _, v in ipairs(Trove.bird_data) do
    table.insert(species_ids, v.species_id)
  end
  load_sonic_defs(species_ids)

end

function Sequencer.startup()
  step_changed()
  slice_changed()
end

return Sequencer
