--- Oystercatcher Engine lib
-- Engine params and functions.
--
-- @module OystercatcherEngine
-- @release v1.0.0
-- @author Mark Eats

local ControlSpec = require "controlspec"

local Oystercatcher = {}

local specs = {}

specs.DETUNE_VARIANCE = ControlSpec.UNIPOLAR
specs.CONTROL_LAG = ControlSpec.new(0, 5, "lin", 0, 1, "s")
specs.AMP = ControlSpec.new(0, 11, "lin", 0, 0.5)
specs.AMP_MOD_LFO = ControlSpec.UNIPOLAR
specs.PANNING = ControlSpec.BIPOLAR
specs.FREQ_MOD_ENV = ControlSpec.BIPOLAR
specs.FREQ_MOD_LFO = ControlSpec.UNIPOLAR
specs.OSC_WAVE_SHAPE = ControlSpec.UNIPOLAR
specs.OSC_WAVE_SHAPE_MOD_ENV = ControlSpec.BIPOLAR
specs.OSC_WAVE_SHAPE_MOD_LFO = ControlSpec.UNIPOLAR
specs.OSC_LEVEL = ControlSpec.new(0, 1, "lin", 0, 1)
specs.NOISE_LEVEL = ControlSpec.UNIPOLAR
specs.LP_FILTER_CUTOFF = ControlSpec.new(20, 20000, "exp", 0, 800, "Hz")
specs.LP_FILTER_CUTOFF_MOD_ENV = ControlSpec.BIPOLAR
specs.LP_FILTER_CUTOFF_MOD_LFO = ControlSpec.UNIPOLAR
specs.LP_FILTER_RESONANCE = ControlSpec.UNIPOLAR
specs.ENV_ATTACK = ControlSpec.new(0.002, 5, "lin", 0, 0.5, "s")
specs.ENV_DECAY = ControlSpec.new(0.002, 10, "lin", 0, 0.3, "s")
specs.ENV_SUSTAIN = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.ENV_RELEASE = ControlSpec.new(0.002, 10, "lin", 0, 0.5, "s")
specs.RING_MOD_MIX = ControlSpec.UNIPOLAR
specs.RING_MOD_MIX_ENV = ControlSpec.BIPOLAR
specs.RING_MOD_MIX_LFO = ControlSpec.UNIPOLAR
specs.RING_MOD_FREQ = ControlSpec.new(20, 20000, 'exp', 0, 50, "Hz")
specs.CHORUS_SEND = ControlSpec.UNIPOLAR
specs.DELAY_SEND = ControlSpec.UNIPOLAR

specs.LFO_FREQ = ControlSpec.new(0.1, 10, 'exp', 0, 4, "Hz")
specs.AUDIO_RATE_LFO_FREQ = ControlSpec.new(0.1, 1000, 'exp', 0, 4, "Hz")

specs.DELAY_TIME = ControlSpec.new(0, 4, "lin", 0, 0.25, "s")
specs.DELAY_MOD_FREQ = ControlSpec.new(0, 2, "lin", 0, 0.2, "Hz")
specs.DELAY_MOD_DEPTH = ControlSpec.UNIPOLAR
specs.DELAY_FEEDBACK = ControlSpec.new(0, 1, 'lin', 0, 0.7)

Oystercatcher.specs = specs


function Oystercatcher.add_chord_params()
  
  params:add_separator("Chord Voice")

  params:add{type = "control", id = "chord_control_lag", name = "Control Lag", controlspec = specs.CONTROL_LAG, action = engine.controlLag}

  params:add{type = "control", id = "chord_detune_variance", name = "Detune Variance", controlspec = specs.DETUNE_VARIANCE, action = engine.detuneVariance}
  params:add{type = "control", id = "chord_freq_mod_env", name = "Freq Mod: Env", controlspec = specs.FREQ_MOD_ENV, action = engine.freqModEnv}
  params:add{type = "control", id = "chord_freq_mod_lfo", name = "Freq Mod: LFO", controlspec = specs.FREQ_MOD_LFO, action = engine.freqModLfo}

  params:add{type = "control", id = "chord_osc_wave_shape", name = "Osc Wave Shape", controlspec = specs.OSC_WAVE_SHAPE, action = engine.oscWaveShape}
  params:add{type = "control", id = "chord_osc_wave_shape_mod_env", name = "Osc Wave Shape Mod: Env", controlspec = specs.OSC_WAVE_SHAPE_MOD_ENV, action = engine.oscWaveShapeModEnv}
  params:add{type = "control", id = "chord_osc_wave_shape_mod_lfo", name = "Osc Wave Shape Mod: LFO", controlspec = specs.OSC_WAVE_SHAPE_MOD_LFO, action = engine.oscWaveShapeModLfo}
  params:add{type = "control", id = "chord_osc_level", name = "Osc Level", controlspec = specs.OSC_LEVEL, action = engine.oscLevel}
  params:add{type = "control", id = "chord_noise_level", name = "Noise Level", controlspec = specs.NOISE_LEVEL, action = engine.noiseLevel}

  params:add{type = "control", id = "chord_lp_filter_cutoff", name = "LP Filter Cutoff", controlspec = specs.LP_FILTER_CUTOFF, action = engine.lpFilterCutoff}
  params:add{type = "control", id = "chord_lp_filter_cutoff_mod_env", name = "LP Filter Cutoff Mod: Env", controlspec = specs.LP_FILTER_CUTOFF_MOD_ENV, action = engine.lpFilterCutoffModEnv}
  params:add{type = "control", id = "chord_lp_filter_cutoff_mod_lfo", name = "LP Filter Cutoff Mod: LFO", controlspec = specs.LP_FILTER_CUTOFF_MOD_LFO, action = engine.lpFilterCutoffModLfo}
  params:add{type = "control", id = "chord_lp_filter_resonance", name = "LP Filter Resonance", controlspec = specs.LP_FILTER_RESONANCE, action = engine.lpFilterResonance}

  params:add{type = "control", id = "chord_env_attack", name = "Env Attack", controlspec = specs.ENV_ATTACK, action = engine.envAttack}
  params:add{type = "control", id = "chord_env_decay", name = "Env Decay", controlspec = specs.ENV_DECAY, action = engine.envDecay}
  params:add{type = "control", id = "chord_env_sustain", name = "Env Sustain", controlspec = specs.ENV_SUSTAIN, action = engine.envSustain}
  params:add{type = "control", id = "chord_env_release", name = "Env Release", controlspec = specs.ENV_RELEASE, action = engine.envRelease}
  params:add{type = "control", id = "chord_amp", name = "Amp", controlspec = specs.AMP, action = engine.amp}
  params:add{type = "control", id = "chord_amp_mod_lfo", name = "Amp Mod: LFO", controlspec = specs.AMP_MOD_LFO, action = engine.ampModLfo}

  params:add{type = "control", id = "chord_lfo_freq", name = "LFO Freq", controlspec = specs.LFO_FREQ, action = engine.lfoFreq}

  params:add{type = "control", id = "chord_ring_mod_mix", name = "Ring Mod Mix", controlspec = specs.RING_MOD_MIX, action = engine.ringModMix}
  params:add{type = "control", id = "chord_ring_mod_mix_env", name = "Ring Mod Mix Mod: Env", controlspec = specs.RING_MOD_MIX_MOD_ENV, action = engine.ringModMixModEnv}
  params:add{type = "control", id = "chord_ring_mod_mix_lfo", name = "Ring Mod Mix Mod: LFO", controlspec = specs.RING_MOD_MIX_MOD_LFO, action = engine.ringModMixModLfo}
  params:add{type = "control", id = "chord_ring_mod_freq", name = "Ring Mod Freq", controlspec = specs.RING_MOD_FREQ, action = engine.ringModFreq}

  params:add{type = "control", id = "chord_chorus_send", name = "Chorus Send", controlspec = specs.CHORUS_SEND, action = engine.chorusSend}
  params:add{type = "control", id = "chord_delay_send", name = "Delay Send", controlspec = specs.DELAY_SEND, action = engine.delaySend}
  
end

function Oystercatcher.add_perc_params()
  
  params:add_separator("Perc Voice")

  params:add{type = "control", id = "perc_detune_variance", name = "Detune Variance", controlspec = specs.DETUNE_VARIANCE}
  params:add{type = "control", id = "perc_freq_mod_env", name = "Freq Mod: Env", controlspec = specs.FREQ_MOD_ENV}
  params:add{type = "control", id = "perc_freq_mod_lfo", name = "Freq Mod: LFO", controlspec = specs.FREQ_MOD_LFO}

  params:add{type = "control", id = "perc_osc_wave_shape", name = "Osc Wave Shape", controlspec = specs.OSC_WAVE_SHAPE}
  params:add{type = "control", id = "perc_osc_wave_shape_mod_env", name = "Osc Wave Shape Mod: Env", controlspec = specs.OSC_WAVE_SHAPE_MOD_ENV}
  params:add{type = "control", id = "perc_osc_wave_shape_mod_lfo", name = "Osc Wave Shape Mod: LFO", controlspec = specs.OSC_WAVE_SHAPE_MOD_LFO}
  params:add{type = "control", id = "perc_osc_level", name = "Osc Level", controlspec = specs.OSC_LEVEL}
  params:add{type = "control", id = "perc_sub_osc_level", name = "Sub Osc Level", controlspec = specs.OSC_LEVEL}
  params:add{type = "control", id = "perc_noise_level", name = "Noise Level", controlspec = specs.NOISE_LEVEL}
  params:add{type = "control", id = "perc_crackle_level", name = "Crackle Level", controlspec = specs.CRACKLE_LEVEL}

  params:add{type = "control", id = "perc_lp_filter_cutoff", name = "LP Filter Cutoff", controlspec = specs.LP_FILTER_CUTOFF}
  params:add{type = "control", id = "perc_lp_filter_cutoff_mod_env", name = "LP Filter Cutoff Mod: Env", controlspec = specs.LP_FILTER_CUTOFF_MOD_ENV}
  params:add{type = "control", id = "perc_lp_filter_cutoff_mod_lfo", name = "LP Filter Cutoff Mod: LFO", controlspec = specs.LP_FILTER_CUTOFF_MOD_LFO}
  params:add{type = "control", id = "perc_lp_filter_resonance", name = "LP Filter Resonance", controlspec = specs.LP_FILTER_RESONANCE}

  params:add{type = "control", id = "perc_env_attack", name = "Env Attack", controlspec = specs.ENV_ATTACK}
  params:add{type = "control", id = "perc_env_release", name = "Env Release", controlspec = specs.ENV_RELEASE}
  params:add{type = "control", id = "perc_amp", name = "Amp", controlspec = specs.AMP}
  params:add{type = "control", id = "perc_amp_mod_lfo", name = "Amp Mod: LFO", controlspec = specs.AMP_MOD_LFO}
  params:add{type = "control", id = "perc_panning", name = "Panning", controlspec = specs.PANNING}

  params:add{type = "control", id = "perc_lfo_freq", name = "LFO Freq", controlspec = specs.AUDIO_RATE_LFO_FREQ}

  params:add{type = "control", id = "perc_chorus_send", name = "Chorus Send", controlspec = specs.CHORUS_SEND}
  params:add{type = "control", id = "perc_delay_send", name = "Delay Send", controlspec = specs.DELAY_SEND}
  
end

function Oystercatcher.add_fx_params()
  
  params:add_separator("FX")

  params:add{type = "control", id = "fx_delay_time", name = "Delay Time", controlspec = specs.DELAY_TIME, action = engine.delayTime}
  params:add{type = "control", id = "fx_delay_mod_freq", name = "Delay Mod Freq", controlspec = specs.DELAY_MOD_FREQ, action = engine.delayModFreq}
  params:add{type = "control", id = "fx_delay_mod_depth", name = "Delay Mod Depth", controlspec = specs.DELAY_MOD_DEPTH, action = engine.delayModDepth}
  params:add{type = "control", id = "fx_delay_feedback", name = "Delay Feedback", controlspec = specs.DELAY_FEEDBACK, action = engine.delayFeedback}
  
end

return Oystercatcher
