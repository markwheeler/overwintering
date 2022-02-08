local MusicUtil = require "musicutil"

local SonicDefs = {}

-- White Stork
SonicDefs["52744"] = {

  -- Key
  musical_scale = MusicUtil.generate_scale(50, "Major", 8), -- D

  -- Defines where the roots are measured from
  chord_start_x = 0.4, -- 0 is left, 1 is right
  chord_start_y = 0.45, -- 0 is top, 0.5 is bottom
  perc_start_x = 0.35,
  perc_start_y = 0.65,

  -- When to expand vs contract trigger order
  -- TODO does this need to vary for each year?
  contract_range = {5, 24},

  -- Dynamic params
  dynamic_params = {

    -- Chord
    chord_osc_wave_shape_low = 0.05,
    chord_osc_wave_shape_high = 0.0,
    chord_noise_level_low = 0.01,
    chord_noise_level_high = 0.004,
    chord_lp_filter_cutoff_low = 600,
    chord_lp_filter_cutoff_high = 80,
    chord_amp_mod_lfo_low = 0.02,
    chord_amp_mod_lfo_high = 0.05,
    chord_lfo_freq_low = 1.6,
    chord_lfo_freq_high = 4,
    chord_env_decay_low = 4,
    chord_env_decay_high = 2,
    chord_env_release_low = 4,
    chord_env_release_high = 3,
    chord_amp_low = 0.4,
    chord_amp_high = 1.6,

    -- Perc
    perc_osc_level_low = 0.3,
    perc_osc_level_high = 0.3,
    perc_sub_osc_level_low = 0.5,
    perc_sub_osc_level_high = 0,
    perc_crackle_level_low = 0.1,
    perc_crackle_level_high = 0.05,
    perc_env_release_low = 4,
    perc_env_release_high = 0.05,
    perc_panning_low = -0.85,
    perc_panning_high = 0.85,
    perc_lp_filter_cutoff_low = 500,
    perc_lp_filter_cutoff_high = 6000,
    perc_lp_filter_resonance_low = 0.5,
    perc_lp_filter_resonance_high = 0.7,
    perc_lfo_freq_low = 0.05,
    perc_lfo_freq_high = 800,
    perc_delay_send_low = 0.6,
    perc_delay_send_high = 0.3,

    -- FX
    fx_delay_feedback_low = 0.8,
    fx_delay_feedback_high = 0.4
  },

  -- Params
  params = {

    -- Chord
    chord_detune_variance = 0.6,
    chord_freq_mod_env = 0.005,
    chord_freq_mod_lfo = 0.002,
    chord_osc_wave_shape_mod_env = 0.5,
    chord_osc_wave_shape_mod_lfo = 0,
    chord_osc_level = 1,
    
    chord_lp_filter_cutoff_mod_env = 0.1,
    chord_lp_filter_cutoff_mod_lfo = 0,
    chord_lp_filter_resonance = 0.4,

    chord_env_attack = 0.0005,
    chord_env_sustain = 0.1,

    chord_ring_mod_mix = 0.065,
    chord_ring_mod_mix_env = 0.25,
    chord_ring_mod_mix_lfo = 0,
    chord_ring_mod_freq = 391.99,

    chord_chorus_send = 0,
    chord_delay_send = 0.2,

    -- Perc
    perc_detune_variance = 0.4,
    perc_freq_mod_env = 0,
    perc_freq_mod_lfo = 0.01,

    perc_osc_wave_shape = 0,
    perc_osc_wave_shape_mod_env = 0,
    perc_osc_wave_shape_mod_lfo = 0.4,
    perc_noise_level = 0,

    perc_lp_filter_cutoff_mod_env = 0.3,
    perc_lp_filter_cutoff_mod_lfo = 0.5,

    perc_env_attack = 0.01,
    perc_amp = 1.6,
    perc_amp_mod_lfo = 0.75,

    perc_chorus_send = 0,

    -- FX
    fx_delay_time = 0.88 * 3,
    fx_delay_mod_freq = 0.2,
    fx_delay_mod_depth = 0.6
  }
}


-- Default
SonicDefs["default"] = {

  -- Key
  musical_scale = MusicUtil.generate_scale(33, "Major", 8), -- A0

  -- Defines where the roots are measured from
  chord_start_x = 0.5, -- 0 is left, 1 is right
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
    chord_osc_wave_shape_high = 0,
    chord_noise_level_low = 0,
    chord_noise_level_high = 0.03,
    chord_lp_filter_cutoff_low = 500,
    chord_lp_filter_cutoff_high = 2000,
    chord_amp_mod_lfo_low = 0.5,
    chord_amp_mod_lfo_high = 0.05,
    chord_lfo_freq_low = 0.01,
    chord_lfo_freq_high = 0.0015,
    chord_env_decay_low = 2,
    chord_env_decay_high = 2,
    chord_env_release_low = 4,
    chord_env_release_high = 5,
    chord_amp_low = 1.1,
    chord_amp_high = 1.1,

    -- Perc
    perc_osc_level_low = 0.15,
    perc_osc_level_high = 1,
    perc_sub_osc_level_low = 0,
    perc_sub_osc_level_high = 0.25,
    perc_crackle_level_low = 0,
    perc_crackle_level_high = 0.5,
    perc_env_release_low = 0.05,
    perc_env_release_high = 1.1,
    perc_panning_low = -0.85,
    perc_panning_high = 0.85,
    perc_lp_filter_cutoff_low = 250,
    perc_lp_filter_cutoff_high = 100,
    perc_lp_filter_resonance_low = 0.1,
    perc_lp_filter_resonance_high = 0.32,
    perc_lfo_freq_low = 0.05,
    perc_lfo_freq_high = 400,
    perc_delay_send_low = 0,
    perc_delay_send_high = 0.65,

    -- FX
    fx_delay_feedback_low = 0.2,
    fx_delay_feedback_high = 1
  },

  -- Params
  params = {

    -- Chord
    chord_detune_variance = 0.4,
    chord_freq_mod_env = 0,
    chord_freq_mod_lfo = 0,
    chord_osc_wave_shape_mod_env = 0,
    chord_osc_wave_shape_mod_lfo = 0,
    chord_osc_level = 1,
    
    chord_lp_filter_cutoff_mod_env = 0,
    chord_lp_filter_cutoff_mod_lfo = 0.05,
    chord_lp_filter_resonance = 0.3,

    chord_env_attack = 5,
    chord_env_sustain = 1,

    chord_ring_mod_mix = 0,
    chord_ring_mod_mix_env = 0,
    chord_ring_mod_mix_lfo = 0.2,
    chord_ring_mod_freq = 223,

    chord_chorus_send = 0.6,
    chord_delay_send = 0.15,

    -- Perc
    perc_detune_variance = 0.4,
    perc_freq_mod_env = 0,
    perc_freq_mod_lfo = 0,

    perc_osc_wave_shape = 0.5,
    perc_osc_wave_shape_mod_env = 0,
    perc_osc_wave_shape_mod_lfo = 0,
    perc_noise_level = 0,

    perc_lp_filter_cutoff_mod_env = 0.5,
    perc_lp_filter_cutoff_mod_lfo = 0,

    perc_env_attack = 0.01,
    perc_amp = 1,
    perc_amp_mod_lfo = 0.75,

    perc_chorus_send = 0.3,

    -- FX
    fx_delay_time = 0.88,
    fx_delay_mod_freq = 0.2,
    fx_delay_mod_depth = 0.2
  }
}

return SonicDefs
