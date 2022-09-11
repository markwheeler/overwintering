-- Ortolan Bunting ---> Brambling

local MusicUtil = require "musicutil"

SonicDef = {

    -- Key
    musical_scale = MusicUtil.generate_scale(43, "Major", 8), -- G
  
    -- Defines where the roots are measured from
    chord_start_x = 0.4, -- 0 is left, 1 is right
    chord_start_y = 0.1, -- 0 is top, 0.5 is bottom
    perc_start_x = 0.4,
    perc_start_y = 0.1,
  
    -- When to expand vs contract trigger order
    contract_range = {37, 6},
  
    -- Dynamic params
    dynamic_params = {
  
      -- Chord
      chord_osc_wave_shape_low = 1,
      chord_osc_wave_shape_high = 0.3,
      chord_noise_level_low = 0.01,
      chord_noise_level_high = 0.1,
      chord_lp_filter_cutoff_low = 500,
      chord_lp_filter_cutoff_high = 950,
      chord_amp_mod_lfo_low = 0.4,
      chord_amp_mod_lfo_high = 0.05,
      chord_lfo_freq_low = 0.005,
      chord_lfo_freq_high = 0.03,
      chord_env_decay_low = 7,
      chord_env_decay_high = 3,
      chord_env_release_low = 6,
      chord_env_release_high = 6,
      chord_amp_low = 0.15,
      chord_amp_high = 0.55,
  
      -- Perc
      perc_osc_level_low = 0.5,
      perc_osc_level_high = 0,
      perc_sub_osc_level_low = 0,
      perc_sub_osc_level_high = 0.5,
      perc_crackle_level_low = 0.1,
      perc_crackle_level_high = 0.5,
      perc_env_release_low = 0.005,
      perc_env_release_high = 0.1,
      perc_panning_low = -0.94,
      perc_panning_high = 0.94,
      perc_lp_filter_cutoff_low = 200,
      perc_lp_filter_cutoff_high = 8000,
      perc_lp_filter_resonance_low = 0.7,
      perc_lp_filter_resonance_high = 0,
      perc_lfo_freq_low = 0.05,
      perc_lfo_freq_high = 300,
      perc_delay_send_low = 0.7,
      perc_delay_send_high = 0.3,
  
      -- FX
      fx_delay_feedback_low = 0.95,
      fx_delay_feedback_high = 0.7
    },
  
    -- Params
    params = {
  
      -- Chord
      chord_detune_variance = 0.1,
      chord_freq_mod_env = 0,
      chord_freq_mod_lfo = 0,
      chord_osc_wave_shape_mod_env = 0,
      chord_osc_wave_shape_mod_lfo = 0,
      chord_osc_level = 1,
      
      chord_lp_filter_cutoff_mod_env = 0,
      chord_lp_filter_cutoff_mod_lfo = 0,
      chord_lp_filter_resonance = 0.85,
  
      chord_env_attack = 4,
      chord_env_sustain = 0.8,
  
      chord_ring_mod_mix = 0,
      chord_ring_mod_mix_env = 0,
      chord_ring_mod_mix_lfo = 0.12,
      chord_ring_mod_freq = 784,
  
      chord_chorus_send = 0.8,
      chord_delay_send = 0.25,
  
      -- Perc
      perc_detune_variance = 1,
      perc_freq_mod_env = 0.1,
      perc_freq_mod_lfo = 0,
  
      perc_osc_wave_shape = 0,
      perc_osc_wave_shape_mod_env = 0,
      perc_osc_wave_shape_mod_lfo = 0,
      perc_noise_level = 0.05,
  
      perc_lp_filter_cutoff_mod_env = 0,
      perc_lp_filter_cutoff_mod_lfo = 0.3,
  
      perc_env_attack = 0.005,
      perc_amp = 0.2,
      perc_amp_mod_lfo = 0.5,
  
      perc_chorus_send = 0.4,
  
      -- FX
      fx_delay_time = 0.17,
      fx_delay_mod_freq = 0.3,
      fx_delay_mod_depth = 0.8
    }
  }

  return SonicDef
  