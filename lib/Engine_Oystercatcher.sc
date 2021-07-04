// CroneEngine_Oystercatcher
// Synth engine for migration.
//
// This engine is fairly specific to the script – for a more general and
// portable engine with a similar structure, see Molly the Poly.
//
// v1.0.0 Mark Eats

Engine_Oystercatcher : CroneEngine {

	classvar maxChordVoices = 3;
	classvar maxPercVoices = 8;
	var chordVoiceGroup;
	var percVoiceGroup;
	var chordVoiceList;
	var percVoiceList;

	var lfo;
	var chorus;
	var delay;
	var mixer;

	var lfoBus;
	var ringModBus;
	var chorusBus;
	var delayBus;
	var mixerBus;
	var delayBuf;

	var detuneVariance = 0;
	var controlLag = 0.01;
	var amp = 1;
	var ampModLfo = 0;
	var freqModEnv = 0;
	var freqModLfo = 0;
	var oscWaveShape = 0;
	var oscWaveShapeModEnv = 0;
	var oscWaveShapeModLfo = 0;
	var oscLevel = 1;
	var noiseLevel = 0;
	var lpFilterCutoff = 440;
	var lpFilterResonance = 0.2;
	var lpFilterCutoffModEnv = 0;
	var lpFilterCutoffModLfo = 0;
	var envAttack = 0.01;
	var envDecay = 0.3;
	var envSustain = 0.5;
	var envRelease = 0.5;
	var ringModMix = 0;
	var ringModMixModEnv = 0;
	var ringModMixModLfo = 0;
	var chorusSend = 0;
	var delaySend = 0;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		chordVoiceGroup = Group.new(context.xg);
		percVoiceGroup = Group.new(context.xg);
		chordVoiceList = List.new();
		percVoiceList = List.new();

		lfoBus = Bus.control(context.server, 1);
		ringModBus = Bus.audio(context.server, 1);
		chorusBus = Bus.audio(context.server, 2);
		delayBus = Bus.audio(context.server, 2);
		mixerBus = Bus.audio(context.server, 2);

		delayBuf = Buffer.alloc(context.server, context.server.sampleRate * 4, 2);


		// Chord voice
		SynthDef(\chordVoice, {
			arg out, lfoIn, ringModIn, freq0 = 440, freq1 = 440, freq2 = 440, freq3 = 440, gate = 0, killGate = 1,
			oscMod0 = 1, oscMod1 = 1, oscMod2 = 1, oscMod3 = 1,
			controlLag = 0.01, detuneVariance = 0, amp = 1, ampModLfo,
			freqModEnv, freqModLfo, oscWaveShape, oscWaveShapeModEnv, oscWaveShapeModLfo, oscLevel, noiseLevel,
			lpFilterCutoff, lpFilterResonance, lpFilterCutoffModEnv, lpFilterCutoffModLfo,
			envAttack, envDecay, envSustain, envRelease,
			ringModMix, ringModMixModEnv, ringModMixModLfo,
			chorusSend = 0.5, delaySend = 0.5;
			var i_nyquist = SampleRate.ir * 0.5, i_cFreq = 48.midicps, signal,
			lfo, ringMod,
			freqModRatio, varSawWaveShape, envelope, killEnvelope, filterCutoffRatio, filterCutoffModRatio;

			// LFO and ring mod in
			lfo = In.kr(lfoIn, 1);
			ringMod = In.ar(ringModIn, 1);

			// Lag inputs
			ampModLfo = Lag.kr(ampModLfo, controlLag);
			freqModEnv = Lag.kr(freqModEnv, controlLag);
			freqModLfo = Lag.kr(freqModLfo, controlLag);
			oscWaveShape = Lag.kr(oscWaveShape, controlLag);
			oscLevel = Lag.kr(oscLevel, controlLag);
			noiseLevel = Lag.kr(noiseLevel, controlLag);
			lpFilterCutoff = Lag.kr(lpFilterCutoff, controlLag);
			lpFilterResonance = Lag.kr(lpFilterResonance, controlLag);
			lpFilterCutoffModEnv = Lag.kr(lpFilterCutoffModEnv, controlLag);
			lpFilterCutoffModLfo = Lag.kr(lpFilterCutoffModLfo, controlLag);
			ringModMix = Lag.kr(ringModMix, controlLag);
			ringModMixModEnv = Lag.kr(ringModMixModEnv, controlLag);
			ringModMixModLfo = Lag.kr(ringModMixModLfo, controlLag);

			// Envelopes
			killGate = killGate + Impulse.kr(0); // Make sure doneAction fires
			killEnvelope = EnvGen.kr(envelope: Env.asr( 0, 1, 0.01), gate: killGate, doneAction: Done.freeSelf);
			envelope = EnvGen.ar(envelope: Env.adsr( envAttack, envDecay, envSustain, envRelease), gate: gate, doneAction: Done.freeSelf);

			// Freqs

			// Note: Would be ideal to do modulation exponentially but its a surprisingly big perf hit
			freqModRatio = ((lfo * freqModLfo) + (envelope * freqModEnv));
			freqModRatio = Select.ar(freqModRatio >= 0, [
				freqModRatio.linlin(-2, 0, 0.25, 1),
				freqModRatio.linlin(0, 2, 1, 4)
			]);
			freq0 = (freq0 * freqModRatio).clip(20, i_nyquist);
			freq1 = (freq1 * freqModRatio).clip(20, i_nyquist);
			freq2 = (freq2 * freqModRatio).clip(20, i_nyquist);
			freq3 = (freq3 * freqModRatio).clip(20, i_nyquist);

			detuneVariance = detuneVariance.linlin(0, 1, 0.001, 0.01);
			freq0 = freq0 * LFNoise2.kr(freq: 0.1, mul: detuneVariance, add: 1);
			freq1 = freq1 * Rand(1 - detuneVariance, 1 + detuneVariance);
			freq2 = freq2 * Rand(1 - detuneVariance, 1 + detuneVariance);
			freq3 = freq3 * Rand(1 - detuneVariance, 1 + detuneVariance);

			// Oscs variable tri to saw
			oscWaveShape = (oscWaveShape + (envelope * oscWaveShapeModEnv) + (lfo.linlin(-1, 1, 0, 1) * oscWaveShapeModLfo)).clip;
			varSawWaveShape = oscWaveShape.linlin(0, 1, 0.51, 0.99);
			signal = (
				VarSaw.ar(freq0, 0, varSawWaveShape, oscMod0.linlin(0, 1, 0.4, 1))
				+ VarSaw.ar(freq1, 0, varSawWaveShape, oscMod1.linlin(0, 1, 0.4, 1))
				+ VarSaw.ar(freq2, 0, varSawWaveShape, oscMod2.linlin(0, 1, 0.4, 1))
				+ VarSaw.ar(freq3, 0, varSawWaveShape, oscMod3.linlin(0, 1, 0.4, 1))
			) * oscWaveShape.linlin(0, 1, 0.25, 0.1) * oscLevel;

			// Noise
			signal = signal + WhiteNoise.ar(noiseLevel.linlin(0, 1, 0.004, 0.5));

			// LP filter tracks freq0
			filterCutoffRatio = Select.kr((freq0 < i_cFreq), [
				i_cFreq + (freq0 - i_cFreq),
				i_cFreq - (i_cFreq - freq0)
			]);
			filterCutoffRatio = filterCutoffRatio / i_cFreq;
			lpFilterCutoff = lpFilterCutoff * filterCutoffRatio;

			// Note: Again, would prefer this to be exponential
			filterCutoffModRatio = (envelope * lpFilterCutoffModEnv * 2) + (lfo * lpFilterCutoffModLfo);
			filterCutoffModRatio = Select.ar(filterCutoffModRatio >= 0, [
				filterCutoffModRatio.linlin(-3, 0, 0.08333333333, 1),
				filterCutoffModRatio.linlin(0, 3, 1, 12)
			]);
			lpFilterCutoff = (lpFilterCutoff * filterCutoffModRatio).clip(20, 20000);

			signal = RLPF.ar(in: signal, freq: lpFilterCutoff, rq: lpFilterResonance.linexp(0, 1, 1, 0.05)); // -12dB
			// signal = RLPF.ar(in: signal, freq: lpFilterCutoff, rq: lpFilterResonance.linexp(0, 1, 1, 0.32)); // -24dB

			// Amp
			signal = signal * envelope * killEnvelope * amp * lfo.linlin(-1, 1, 1 - ampModLfo, 1);

			// Ring mod
			signal = SelectX.ar((ringModMix + (envelope * ringModMixModEnv) + (lfo * ringModMixModLfo)).clip, [signal, signal * ringMod]);

			// Sends
			signal = signal.dup;
			Out.ar(chorusBus, signal * chorusSend);
			Out.ar(delayBus, signal * delaySend);

			Out.ar(out, signal);
		}).add;

		// LFO for chordVoice
		lfo = SynthDef(\lfo, {
			arg lfoOut, ringModOut, lfoFreq = 3, ringModFreq = 50;
			var lfo, ringMod;

			lfo = LFTri.kr(lfoFreq);
			lfo = Lag.kr(lfo, 0.005);

			Out.kr(lfoOut, lfo);

			ringMod = SinOsc.ar(ringModFreq);
			Out.ar(ringModOut, ringMod);

		}).play(target:context.xg, args: [\lfoOut, lfoBus, \ringModOut, ringModBus], addAction: \addToHead);


		// Perc voice
		SynthDef(\percVoice, {
			arg out, freq0 = 440, freq1 = 440, gate = 0, killGate = 1, detuneVariance = 0, vel = 1.0, amp = 1, ampModLfo = 0, panning = 0,
			freqModEnv = 0, freqModLfo = 0,
			oscWaveShape = 0, oscWaveShapeModEnv = 0, oscWaveShapeModLfo = 0, oscLevel = 1, subOscLevel = 0, noiseLevel = 0, crackleLevel = 0,
			lpFilterCutoff = 2000, lpFilterCutoffModEnv = 0, lpFilterCutoffModLfo = 0, lpFilterResonance = 0.2,
			envAttack = 0.1, envRelease = 0.5,
			lfoFreq = 20,
			chorusSend = 0, delaySend = 0;
			var i_nyquist = SampleRate.ir * 0.5, i_cFreq = 48.midicps, signal, noise,
			lfo, killEnvelope, envelope, freqModRatio, filterCutoffRatio, filterCutoffModRatio;

			// Envelopes
			killGate = killGate + Impulse.kr(0); // Make sure doneAction fires
			killEnvelope = EnvGen.kr(envelope: Env.asr( 0, 1, 0.01), gate: killGate, doneAction: Done.freeSelf);

			envelope = EnvGen.ar(envelope: Env.perc( envAttack, envRelease), gate: gate, doneAction: Done.freeSelf);

			// LFO
			lfo = SinOsc.ar(lfoFreq);

			// Freq
			freqModRatio = ((lfo * freqModLfo) + (envelope * freqModEnv));
			freqModRatio = Select.ar(freqModRatio >= 0, [
				freqModRatio.linlin(-2, 0, 0.25, 1),
				freqModRatio.linlin(0, 2, 1, 4)
			]);
			freq0 = (freq0 * freqModRatio).clip(20, i_nyquist);
			freq1 = (freq1 * freqModRatio).clip(20, i_nyquist);
			detuneVariance = detuneVariance.linlin(0, 1, 0.001, 0.01);
			freq0 = freq0 * Rand(1 - detuneVariance, 1 + detuneVariance);
			freq1 = freq1 * Rand(1 - detuneVariance, 1 + detuneVariance);

			// Osc
			oscWaveShape = (oscWaveShape + (envelope * oscWaveShapeModEnv) + (lfo.linlin(-1, 1, 0, 1) * oscWaveShapeModLfo)).clip;
			signal = VarSaw.ar(freq0, 0, oscWaveShape.linlin(0, 1, 0.505, 0.99)) * oscWaveShape.linlin(0, 1, 0.33, 0.15) * oscLevel;
			signal = signal + VarSaw.ar(freq1, 0, 0.5, subOscLevel * 0.33);

			// Filtered noise
			noise = WhiteNoise.ar(noiseLevel);
			noise = noise + LPF.ar(Crackle.ar(2.0, crackleLevel), 2000);
			noise = HPF.ar(noise, 300);
			signal = signal + noise;

			// LP filter
			filterCutoffRatio = Select.kr((freq0 < i_cFreq), [
				i_cFreq + (freq0 - i_cFreq),
				i_cFreq - (i_cFreq - freq0)
			]);
			filterCutoffRatio = filterCutoffRatio / i_cFreq;
			lpFilterCutoff = lpFilterCutoff * filterCutoffRatio;

			filterCutoffModRatio = (envelope * lpFilterCutoffModEnv * 2) + (lfo * lpFilterCutoffModLfo);
			filterCutoffModRatio = Select.ar(filterCutoffModRatio >= 0, [
				filterCutoffModRatio.linlin(-3, 0, 0.08333333333, 1),
				filterCutoffModRatio.linlin(0, 3, 1, 12)
			]);
			lpFilterCutoff = (lpFilterCutoff * filterCutoffModRatio).clip(20, 20000);

			signal = RLPF.ar(in: signal, freq: lpFilterCutoff, rq: lpFilterResonance.linexp(0, 1, 1, 0.05));
			signal = RLPF.ar(in: signal, freq: lpFilterCutoff, rq: lpFilterResonance.linexp(0, 1, 1, 0.32)); // -24dB

			// Amp
			signal = signal * envelope * killEnvelope * vel * amp * lfo.linlin(-1, 1, 1 - ampModLfo, 1) * 0.7;

			// Panning
			signal = Pan2.ar(signal, panning);

			// Sends
			Out.ar(chorusBus, signal * chorusSend);
			Out.ar(delayBus, signal * delaySend);

			Out.ar(out, signal);
		}).add;


		// Chorus
		chorus = SynthDef(\chorus, {
			arg in, chorusOut;
			var signal, chorusLfo, chorusPreDelay = 0.01, chorusDepth = 0.0053, chorusDelay;

			signal = In.ar(in, 2);

			chorusLfo = LFPar.kr(0.6);
			chorusDelay = chorusPreDelay + chorusDepth;

			signal = Array.with(
				DelayC.ar(in: signal[0], maxdelaytime: chorusDelay, delaytime: chorusLfo.range(chorusPreDelay, chorusDelay)),
				DelayC.ar(in: signal[1], maxdelaytime: chorusDelay, delaytime: chorusLfo.range(chorusDelay, chorusPreDelay))
			);
			signal = LPF.ar(signal, 14000);

			Out.ar(chorusOut, signal);

		}).play(target:context.xg, args: [\in, chorusBus, \chorusOut, mixerBus], addAction: \addToTail);

		// Delay (based on SC's ping pong delay)
		delay = SynthDef(\delay, {
			arg  bufnum, in, delayOut, delayTime = 0.2, modFreq = 0.2, modDepth = 0, feedback = 0.7;
			var signal, delaySamps, phase, feedbackChannels, delayedSignals, frames;

			frames = BufFrames.kr(bufnum);
			delayTime = delayTime + (SinOsc.kr(modFreq) * modDepth * 0.005);
			delaySamps = max(0, delayTime * SampleRate.ir - ControlDur.ir).round;

			signal = In.ar(in, 2);
			feedbackChannels = LocalIn.ar(2) * feedback;
			feedbackChannels = BHiShelf.ar(feedbackChannels, 1200, 1, -1.75); // Darken in feedback loop

			phase = Phasor.ar(0, 1, 0, frames);
			delayedSignals = BufRd.ar(2, bufnum, (phase - delaySamps).wrap(0, frames), 0);

			LocalOut.ar(delayedSignals);
			BufWr.ar((signal + feedbackChannels) <! delayedSignals.asArray.first, bufnum, phase, 1);
			// TODO re-introduce .rotate(1) ?

			Out.ar(delayOut, delayedSignals);

		}).play(target:context.xg, args: [\bufnum, delayBuf, \in, delayBus, \delayOut, mixerBus], addAction: \addToTail);


		// Mixer
		mixer = SynthDef(\mixer, {
			arg in, out;
			var signal;

			signal = In.ar(in, 2);

			// EQ (reduce lows)
			signal = BLowShelf.ar(signal, 200, 1, -6);

			// Compression etc
			signal = CompanderD.ar(in: signal, thresh: 0.4, slopeBelow: 1, slopeAbove: 0.25, clampTime: 0.002, relaxTime: 0.01);
			signal = tanh(signal).softclip;

			Out.ar(out, signal);

		}).play(target:context.xg, args: [\in, mixerBus, \out, context.out_b], addAction: \addToTail);

		this.addCommands;
	}


	// Commands

	addCommands {

		// chordOn(id, freq0, freq1, freq2, freq3, oscMod0, oscMod1, oscMod2, oscMod3)
		this.addCommand(\chordOn, "iffffffff", {
			arg msg;
			var id = msg[1], freq0 = msg[2], freq1 = msg[3], freq2 = msg[4], freq3 = msg[5],
			oscMod0 = msg[6], oscMod1 = msg[7], oscMod2 = msg[8], oscMod3 = msg[9];
			var voiceToRemove, newVoice;

			// Stop all playing chords
			chordVoiceGroup.set(\gate, 0);

			// Remove voice if ID matches or there are too many
			voiceToRemove = chordVoiceList.detect{arg item; item.id == id};
			if(voiceToRemove.isNil && (chordVoiceList.size >= maxChordVoices), {
				voiceToRemove = chordVoiceList.last;
			});
			if(voiceToRemove.notNil, {
				voiceToRemove.theSynth.set(\killGate, 0);
				chordVoiceList.remove(voiceToRemove);
			});

			// Add new chord
			context.server.makeBundle(nil, {
				newVoice = (id: id, theSynth: Synth.new(defName: \chordVoice, args: [
					\out, mixerBus,
					\lfoIn, lfoBus,
					\ringModIn, ringModBus,
					\freq0, freq0,
					\freq1, freq1,
					\freq2, freq2,
					\freq3, freq3,
					\oscMod0, oscMod0,
					\oscMod1, oscMod1,
					\oscMod2, oscMod2,
					\oscMod3, oscMod3,
					\gate, 1,
					\controlLag, controlLag,
					\amp, amp,
					\ampModLfo, ampModLfo,
					\freqModEnv, freqModEnv,
					\freqModLfo, freqModLfo,
					\oscWaveShape, oscWaveShape,
					\oscWaveShapeModEnv, oscWaveShapeModEnv,
					\oscWaveShapeModLfo, oscWaveShapeModLfo,
					\oscLevel, oscLevel,
					\noiseLevel, noiseLevel,
					\lpFilterCutoff, lpFilterCutoff,
					\lpFilterResonance, lpFilterResonance,
					\lpFilterCutoffModEnv, lpFilterCutoffModEnv,
					\lpFilterCutoffModLfo, lpFilterCutoffModLfo,
					\envAttack, envAttack,
					\envDecay, envDecay,
					\envSustain, envSustain,
					\envRelease, envRelease,
					\ringModMix, ringModMix,
					\ringModMixModEnv, ringModMixModEnv,
					\ringModMixModLfo, ringModMixModLfo,
					\chorusSend, chorusSend,
					\delaySend, delaySend,
				], target: chordVoiceGroup).onFree({ chordVoiceList.remove(newVoice); }));

				chordVoiceList.addFirst(newVoice);
			});
		});

		// chordOff()
		this.addCommand(\chordOff, "", {
			arg msg;
			chordVoiceGroup.set(\gate, 0);
		});

		// percOn(id, freq0, freq1, detuneVariance, vel, ampModLfo, freqModEnv, freqModLfo,
		// oscWaveShape, oscWaveShapeModEnv, oscWaveShapeModLfo, subOscLevel, noiseLevel, crackleLevel
		// lpFilterCutoff, lpFilterCutoffModEnv, lpFilterCutoffModLfo, lpFilterResonance,
		// envAttack, envRelease, lfoFreq, chorusSend, delaySend)

		this.addCommand(\percOn, "ifffffffffffffffffffffffff", {
			arg msg;
			var id = msg[1], freq0 = msg[2], freq1 = msg[3], detuneVariance = msg[4], vel = msg[5] ?? 1, amp = msg[6] ?? 1, ampModLfo = msg[7], panning = msg[8],
			freqModEnv = msg[9], freqModLfo = msg[10],
			oscWaveShape = msg[11], oscWaveShapeModEnv = msg[12], oscWaveShapeModLfo = msg[13],
			oscLevel = msg[14], subOscLevel = msg[15], noiseLevel = msg[16], crackleLevel = msg[17],
			lpFilterCutoff = msg[18] ?? 2000, lpFilterCutoffModEnv = msg[19], lpFilterCutoffModLfo = msg[20], lpFilterResonance = msg[21],
			envAttack = msg[22] ?? 0.1, envRelease = msg[23] ?? 0.5, lfoFreq = msg[24] ?? 20, chorusSend = msg[25], delaySend = msg[26];
			var voiceToRemove, newVoice;

			// Remove voice if ID matches or there are too many
			voiceToRemove = percVoiceList.detect{arg item; item.id == id};
			if(voiceToRemove.isNil && (percVoiceList.size >= maxPercVoices), {
				voiceToRemove = percVoiceList.last;
			});
			if(voiceToRemove.notNil, {
				voiceToRemove.theSynth.set(\gate, 0);
				voiceToRemove.theSynth.set(\killGate, 0);
				percVoiceList.remove(voiceToRemove);
			});

			// Add new voice
			context.server.makeBundle(nil, {
				newVoice = (id: id, theSynth: Synth.new(defName: \percVoice, args: [
					\out, mixerBus,
					\freq0, freq0,
					\freq1, freq1,
					\gate, 1,
					\detuneVariance, detuneVariance,
					\vel, vel.linlin(0, 1, 0.3, 1),
					\amp, amp,
					\ampModLfo, ampModLfo,
					\panning, panning,
					\freqModEnv, freqModEnv,
					\freqModLfo, freqModLfo,
					\oscWaveShape, oscWaveShape,
					\oscWaveShapeModEnv, oscWaveShapeModEnv,
					\oscWaveShapeModLfo, oscWaveShapeModLfo,
					\oscLevel, oscLevel,
					\subOscLevel, subOscLevel,
					\noiseLevel, noiseLevel,
					\crackleLevel, crackleLevel,
					\lpFilterCutoff, lpFilterCutoff,
					\lpFilterCutoffModEnv, lpFilterCutoffModEnv,
					\lpFilterCutoffModLfo, lpFilterCutoffModLfo,
					\lpFilterResonance, lpFilterResonance,
					\envAttack, envAttack,
					\envRelease, envRelease,
					\lfoFreq, lfoFreq,
					\chorusSend, chorusSend,
					\delaySend, delaySend,
				], target: percVoiceGroup).onFree({ percVoiceList.remove(newVoice); }));

				percVoiceList.addFirst(newVoice);
			});
		});

		// percOff(id)
		this.addCommand(\percOff, "i", {
			arg msg;
			var voice = percVoiceList.detect{arg v; v.id == msg[1]};
			if(voice.notNil, {
				voice.theSynth.set(\gate, 0);
			});
		});

		// percOffAll()
		this.addCommand(\percOffAll, "i", {
			arg msg;
			percVoiceGroup.set(\gate, 0);
		});


		// Chord voice

		this.addCommand(\detuneVariance, "f", {
			arg msg;
			detuneVariance = msg[1];
			chordVoiceGroup.set(\detuneVariance, detuneVariance);
		});

		this.addCommand(\controlLag, "f", {
			arg msg;
			controlLag = msg[1];
			chordVoiceGroup.set(\controlLag, controlLag);
		});

		this.addCommand(\amp, "f", {
			arg msg;
			amp = msg[1];
			chordVoiceGroup.set(\amp, amp);
		});

		this.addCommand(\ampModLfo, "f", {
			arg msg;
			ampModLfo = msg[1];
			chordVoiceGroup.set(\ampModLfo, ampModLfo);
		});

		this.addCommand(\freqModEnv, "f", {
			arg msg;
			freqModEnv = msg[1];
			chordVoiceGroup.set(\freqModEnv, freqModEnv);
		});

		this.addCommand(\freqModLfo, "f", {
			arg msg;
			freqModLfo = msg[1];
			chordVoiceGroup.set(\freqModLfo, freqModLfo);
		});

		this.addCommand(\oscWaveShape, "f", {
			arg msg;
			oscWaveShape = msg[1];
			chordVoiceGroup.set(\oscWaveShape, oscWaveShape);
		});

		this.addCommand(\oscWaveShapeModEnv, "f", {
			arg msg;
			oscWaveShapeModEnv = msg[1];
			chordVoiceGroup.set(\oscWaveShapeModEnv, oscWaveShapeModEnv);
		});

		this.addCommand(\oscWaveShapeModLfo, "f", {
			arg msg;
			oscWaveShapeModLfo = msg[1];
			chordVoiceGroup.set(\oscWaveShapeModLfo, oscWaveShapeModLfo);
		});

		this.addCommand(\oscLevel, "f", {
			arg msg;
			oscLevel = msg[1];
			chordVoiceGroup.set(\oscLevel, oscLevel);
		});

		this.addCommand(\noiseLevel, "f", {
			arg msg;
			noiseLevel = msg[1];
			chordVoiceGroup.set(\noiseLevel, noiseLevel);
		});

		this.addCommand(\lpFilterCutoff, "f", {
			arg msg;
			lpFilterCutoff = msg[1];
			chordVoiceGroup.set(\lpFilterCutoff, lpFilterCutoff);
		});

		this.addCommand(\lpFilterResonance, "f", {
			arg msg;
			lpFilterResonance = msg[1];
			chordVoiceGroup.set(\lpFilterResonance, lpFilterResonance);
		});

		this.addCommand(\lpFilterCutoffModEnv, "f", {
			arg msg;
			lpFilterCutoffModEnv = msg[1];
			chordVoiceGroup.set(\lpFilterCutoffModEnv, lpFilterCutoffModEnv);
		});

		this.addCommand(\lpFilterCutoffModLfo, "f", {
			arg msg;
			lpFilterCutoffModLfo = msg[1];
			chordVoiceGroup.set(\lpFilterCutoffModLfo, lpFilterCutoffModLfo);
		});

		this.addCommand(\envAttack, "f", {
			arg msg;
			envAttack = msg[1];
			chordVoiceGroup.set(\envAttack, envAttack);
		});

		this.addCommand(\envDecay, "f", {
			arg msg;
			envDecay = msg[1];
			chordVoiceGroup.set(\envDecay, envDecay);
		});

		this.addCommand(\envSustain, "f", {
			arg msg;
			envSustain = msg[1];
			chordVoiceGroup.set(\envSustain, envSustain);
		});

		this.addCommand(\envRelease, "f", {
			arg msg;
			envRelease = msg[1];
			chordVoiceGroup.set(\envRelease, envRelease);
		});

		this.addCommand(\ringModMix, "f", {
			arg msg;
			ringModMix = msg[1];
			chordVoiceGroup.set(\ringModMix, ringModMix);
		});

		this.addCommand(\ringModMixModEnv, "f", {
			arg msg;
			ringModMixModEnv = msg[1];
			chordVoiceGroup.set(\ringModMixModEnv, ringModMixModEnv);
		});

		this.addCommand(\ringModMixModLfo, "f", {
			arg msg;
			ringModMixModLfo = msg[1];
			chordVoiceGroup.set(\ringModMixModLfo, ringModMixModLfo);
		});

		this.addCommand(\chorusSend, "f", {
			arg msg;
			chorusSend = msg[1];
			chordVoiceGroup.set(\chorusSend, chorusSend);
		});

		this.addCommand(\delaySend, "f", {
			arg msg;
			delaySend = msg[1];
			chordVoiceGroup.set(\delaySend, delaySend);
		});


		// LFO

		this.addCommand(\lfoFreq, "f", {
			arg msg;
			lfo.set(\lfoFreq, msg[1]);
		});

		this.addCommand(\ringModFreq, "f", {
			arg msg;
			lfo.set(\ringModFreq, msg[1]);
		});


		// FX

		this.addCommand(\delayTime, "f", {
			arg msg;
			delay.set(\delayTime, msg[1].clip(0, 2));
		});

		this.addCommand(\delayModFreq, "f", {
			arg msg;
			delay.set(\modFreq, msg[1].clip(0, 2));
		});

		this.addCommand(\delayModDepth, "f", {
			arg msg;
			delay.set(\modDepth, msg[1].clip(0, 1));
		});

		this.addCommand(\delayFeedback, "f", {
			arg msg;
			delay.set(\feedback, msg[1].clip(0, 1));
		});

	}

	free {
		chordVoiceGroup.free;
		percVoiceGroup.free;
		lfo.free;
		chorus.free;
		delay.free;
		mixer.free;

		lfoBus.free;
		ringModBus.free;
		chorusBus.free;
		delayBus.free;
		mixerBus.free;
		delayBuf.free;

	}
}
