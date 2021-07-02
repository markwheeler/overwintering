local MusicUtil = require "musicutil"

local SonicDefs = {}

SonicDefs.bomgar = {

  -- Key
  musical_scale = MusicUtil.generate_scale(33, "Major", 8), -- A0

  -- Defines where the roots are measured from
  chord_start_x = 0.5, -- 0 is let, 1 is right
  chord_start_y = 0.5, -- 0 is top, 0.5 is bottom
  perc_start_x = 0.7,
  perc_start_y = 0.2,

  -- When to expand vs contract trigger order
  -- TODO does this need to vary for each year?
  contract_range = {12, 35},

  -- Dynamic params
  dynamic_params = {

    -- Chord
    chord_osc_wave_shape_low = 1,
    chord_osc_wave_shape_high = 0.2,
    chord_noise_level_low = 0.002,
    chord_noise_level_high = 0.03,
    chord_lp_filter_cutoff_low = 600,
    chord_lp_filter_cutoff_high = 2000,

    -- Perc
    perc_env_release_low = 0.03,
    perc_env_release_high = 1.5,
    perc_panning_low = -1,
    perc_panning_high = 1,
    perc_lp_filter_cutoff_low = 200,
    perc_lp_filter_cutoff_high = 900,
    perc_delay_send_low = 0.1,
    perc_delay_send_high = 1
  },

  -- Params
  params = {

    -- Chord
    chord_detune_variance = 0.2,
    chord_freq_mod_env = 0,
    chord_freq_mod_lfo = 0,
    chord_osc_wave_shape_mod_env = 0,
    chord_osc_wave_shape_mod_lfo = 0,
    chord_osc_level = 1,
        
    chord_lp_filter_cutoff_mod_env = 0,
    chord_lp_filter_cutoff_mod_lfo = 0.05,
    chord_lp_filter_resonance = 0,

    chord_env_attack = 5,
    chord_env_decay = 2,
    chord_env_sustain = 1,
    chord_env_release = 5,
    chord_amp = 0.7,
    chord_amp_mod_lfo = 0.05,

    chord_lfo_freq = 0.001,

    chord_ring_mod_mix = 0,
    chord_ring_mod_mix_env = 0,
    chord_ring_mod_mix_lfo = 0.2,
    chord_ring_mod_freq = 223,

    chord_chorus_send = 0.4,
    chord_delay_send = 0.2,

    -- Perc
    perc_detune_variance = 0.3,
    perc_freq_mod_env = 0,
    perc_freq_mod_lfo = 0,

    perc_osc_wave_shape = 0.5,
    perc_osc_wave_shape_mod_env = 0.3,
    perc_osc_wave_shape_mod_lfo = 0.1,
    perc_osc_level = 1,
    perc_noise_level = 0,
    perc_crackle_level = 0.2,

    perc_lp_filter_cutoff_mod_env = 0.2,
    perc_lp_filter_cutoff_mod_lfo = 0,
    perc_lp_filter_resonance = 0.15,

    perc_env_attack = 0.02,
    perc_amp = 0.4,
    perc_amp_mod_lfo = 0.1,

    perc_lfo_freq = 0.3,
    perc_chorus_send = 0.3,

    -- FX
    fx_delay_time = 0.24,
    fx_delay_mod_freq = 0.2,
    fx_delay_mod_depth = 0.2,
    fx_delay_feedback = 0.7
  }
}

return SonicDefs
