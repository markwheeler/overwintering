local MusicUtil = require "musicutil"

local SonicDefs = {}

SonicDefs.bomgar = {

    -- Key
    musical_scale = MusicUtil.generate_scale(33, "Major", 8), -- A0

    -- Defines where the root of the chord is measured from
    chord_start_x = 0.5,
    chord_start_y = 0.5,

    -- Dynamic params
    dynamic_params = {
        chord_osc_wave_shape_low = 1,
        chord_osc_wave_shape_high = 0.2,
        chord_noise_level_low = 0.002,
        chord_noise_level_high = 0.02,
        chord_lp_filter_cutoff_low = 600,
        chord_lp_filter_cutoff_high = 1400,
    },

    -- Params
    params = {
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
        chord_amp = 0.5,
        chord_amp_mod_lfo = 0.05,

        chord_lfo_freq = 0.001,

        chord_ring_mod_mix = 0,
        chord_ring_mod_mix_env = 0,
        chord_ring_mod_mix_lfo = 0.2,
        chord_ring_mod_freq = 223,

        chord_chorus_send = 0.4,
        chord_delay_send = 0.2
    }
}

return SonicDefs
