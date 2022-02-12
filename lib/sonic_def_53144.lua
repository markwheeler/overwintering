-- Rough-legged Buzzard

local MusicUtil = require "musicutil"

SonicDef = {

    -- Key
    musical_scale = MusicUtil.generate_scale(40, "Major", 8), -- E
  
    -- Defines where the roots are measured from
    chord_start_x = 0.55, -- 0 is left, 1 is right
    chord_start_y = 0, -- 0 is top, 0.5 is bottom
    perc_start_x = 0.5,
    perc_start_y = 0.3,
  
    -- When to expand vs contract trigger order
    -- TODO does this need to vary for each year?
    contract_range = {2, 34},
  
    -- Dynamic params
    dynamic_params = {
  
      -- Chord
      chord_osc_wave_shape_low = 1,
      chord_osc_wave_shape_high = 0,
      chord_noise_level_low = 0.52,
      chord_noise_level_high = 0.015,
      chord_lp_filter_cutoff_low = 90,
      chord_lp_filter_cutoff_high = 150,
      chord_amp_mod_lfo_low = 0.2,
      chord_amp_mod_lfo_high = 0.5,
      chord_lfo_freq_low = 0.009,
      chord_lfo_freq_high = 0.001,
      chord_env_decay_low = 2,
      chord_env_decay_high = 3,
      chord_env_release_low = 4,
      chord_env_release_high = 6,
      chord_amp_low = 0.9,
      chord_amp_high = 1.8,
  
      -- Perc
      perc_osc_level_low = 0.15,
      perc_osc_level_high = 1,
      perc_sub_osc_level_low = 0.5,
      perc_sub_osc_level_high = 0,
      perc_crackle_level_low = 0,
      perc_crackle_level_high = 0.3,
      perc_env_release_low = 4,
      perc_env_release_high = 1,
      perc_panning_low = -0.9,
      perc_panning_high = 0.9,
      perc_lp_filter_cutoff_low = 33,
      perc_lp_filter_cutoff_high = 90,
      perc_lp_filter_resonance_low = 0.4,
      perc_lp_filter_resonance_high = 0,
      perc_lfo_freq_low = 0.05,
      perc_lfo_freq_high = 100,
      perc_delay_send_low = 0.3,
      perc_delay_send_high = 0.7,
  
      -- FX
      fx_delay_feedback_low = 0.2,
      fx_delay_feedback_high = 0.85
    },
  
    -- Params
    params = {
  
      -- Chord
      chord_detune_variance = 0.7,
      chord_freq_mod_env = 0,
      chord_freq_mod_lfo = 0,
      chord_osc_wave_shape_mod_env = 0,
      chord_osc_wave_shape_mod_lfo = 0,
      chord_osc_level = 0.45,
      
      chord_lp_filter_cutoff_mod_env = -0.1,
      chord_lp_filter_cutoff_mod_lfo = 0.1,
      chord_lp_filter_resonance = 0,
  
      chord_env_attack = 1.5,
      chord_env_sustain = 0.7,
  
      chord_ring_mod_mix = 0,
      chord_ring_mod_mix_env = 0,
      chord_ring_mod_mix_lfo = 0.05,
      chord_ring_mod_freq = 293,
  
      chord_chorus_send = 0.35,
      chord_delay_send = 0.6,
  
      -- Perc
      perc_detune_variance = 0.5,
      perc_freq_mod_env = 0,
      perc_freq_mod_lfo = 0,
  
      perc_osc_wave_shape = 0.5,
      perc_osc_wave_shape_mod_env = 0,
      perc_osc_wave_shape_mod_lfo = 0,
      perc_noise_level = 0,
  
      perc_lp_filter_cutoff_mod_env = 0.2,
      perc_lp_filter_cutoff_mod_lfo = 0,
  
      perc_env_attack = 0.01,
      perc_amp = 1,
      perc_amp_mod_lfo = 0.5,
  
      perc_chorus_send = 0,
  
      -- FX
      fx_delay_time = 4,
      fx_delay_mod_freq = 0.01,
      fx_delay_mod_depth = 0.5
    }
  }

  return SonicDef
  