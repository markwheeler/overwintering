-- White Stork

local MusicUtil = require "musicutil"

SonicDef = {

    -- Key
    musical_scale = MusicUtil.generate_scale(50, "Major", 8), -- D
  
    -- Defines where the roots are measured from
    chord_start_x = 0.45, -- 0 is left, 1 is right
    chord_start_y = 0.25, -- 0 is top, 0.5 is bottom
    perc_start_x = 0.45,
    perc_start_y = 0.25,
  
    -- When to expand vs contract trigger order
    contract_range = {5, 24},
  
    -- Dynamic params
    dynamic_params = {
  
      -- Chord
      chord_osc_wave_shape_low = 0.05,
      chord_osc_wave_shape_high = 0,
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
      chord_amp_low = 0.75,
      chord_amp_high = 1.6,
  
      -- Perc
      perc_osc_level_low = 0.3,
      perc_osc_level_high = 0,
      perc_sub_osc_level_low = 0.1,
      perc_sub_osc_level_high = 0.22,
      perc_crackle_level_low = 0.11,
      perc_crackle_level_high = 0,
      perc_env_release_low = 2,
      perc_env_release_high = 0.4,
      perc_panning_low = -0.85,
      perc_panning_high = 0.85,
      perc_lp_filter_cutoff_low = 600,
      perc_lp_filter_cutoff_high = 5000,
      perc_lp_filter_resonance_low = 0.05,
      perc_lp_filter_resonance_high = 0.25,
      perc_lfo_freq_low = 0.3,
      perc_lfo_freq_high = 800,
      perc_delay_send_low = 0.7,
      perc_delay_send_high = 0.3,
  
      -- FX
      fx_delay_feedback_low = 0.9,
      fx_delay_feedback_high = 0.5
    },
  
    -- Params
    params = {
  
      -- Chord
      chord_detune_variance = 0.1,
      chord_freq_mod_env = 0.004,
      chord_freq_mod_lfo = 0.0015,
      chord_osc_wave_shape_mod_env = 0.5,
      chord_osc_wave_shape_mod_lfo = 0,
      chord_osc_level = 1,
      
      chord_lp_filter_cutoff_mod_env = 0.1,
      chord_lp_filter_cutoff_mod_lfo = 0,
      chord_lp_filter_resonance = 0.4,
  
      chord_env_attack = 0.0001,
      chord_env_sustain = 0.07,
  
      chord_ring_mod_mix = 0.065,
      chord_ring_mod_mix_env = 0.25,
      chord_ring_mod_mix_lfo = 0,
      chord_ring_mod_freq = 391.99,
  
      chord_chorus_send = 0,
      chord_delay_send = 0.2,
  
      -- Perc
      perc_detune_variance = 0.2,
      perc_freq_mod_env = 0,
      perc_freq_mod_lfo = 0.01,
  
      perc_osc_wave_shape = 0,
      perc_osc_wave_shape_mod_env = 0,
      perc_osc_wave_shape_mod_lfo = 0.4,
      perc_noise_level = 0,
  
      perc_lp_filter_cutoff_mod_env = 0,
      perc_lp_filter_cutoff_mod_lfo = 0.33,
  
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
  
  return SonicDef
  