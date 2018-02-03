(
//
// MEGAZORD SYNTH by Tomer Baruch
//
// Based on NES waveforms by Adventure Kid.
// Originally written to work on a Raspberry Pi 3 with a Pisound interface and Novation Launchkey mini Midi Controller.
//
// github.com/baruchtomer
//
~setControls = {
	~delay.free; ~delay=nil;
	~setArp = {
		n.size.do({|i| n[i] = ~stopFunc.value(n[i])});
		m.keys.set({p.play(m.keys.getKeys)}, {p.play(m.keys.getKeys)});
		~st.arpOn = true;
	};
	~stopArp = {
		p.stop;
		m.keys.set({|vel, note| n[note] = ~playFunc.value(note) }, {|note| n[note] = ~stopFunc.value(n[note])});
		~st.arpOn = false;
	};
	~setDelay = {
		if (~delay.isNil) {
			~delay = Synth.tail(s, \stDelay, [\bus, 0, \time, ~st.bpm.bpmms*0.75, \repeat, ~st.delayRepeat, \mix, ~st.delayMix, \spread, ~st.delaySpread]);
			~st.delayOn = true;
		}
	};
	~stopDelay = {
		~delay.set(\gate, 0);
		~delay = nil;
		~st.delayOn = false;
	};
	~updateDelay = {
		if (~delay.notNil) {~delay.set(\mix, ~st.delayMix, \repeat, ~st.delayRepeat, \spread, ~st.delaySpread)};
	};
	~stopArp.value; //start keys;
	m.knobs[0].set({|val| ~st.lpf = val.linexp(0,1, 50, 10000); ~filter.set(\lpf, ~st.lpf )});
	m.knobs[1].set({|val| ~st.rlpf = val.linexp(0,1, 2, 0.2); ~filter.set(\rlpf, ~st.rlpf )});
	m.knobs[2].set({|val| p.set(\beats, ~beats[(val*(~beats.size-1)).asInt])});
	m.knobs[3].set({|val| p.set(\dur, val.linlin(0,1,0.2,1))});
	m.knobs[4].set({|val| p.set(\octaves, val.linlin(0,1,1,5).asInt)});
	m.knobs[5].set({|val| ~st.jitter = val.linexp(0, 1, 0.0001, 0.2)});
	m.knobs[6].set({|val|
		~st.delayMix = val.linlin(0,1, 0.2, 0.6);
		~st.delayRepeat = val;
		~st.delaySpread = val.linlin(0,0.5, 0.0, 1);
		~updateDelay.value;
	});
	m.knobs[7].set({|val| ~st.amp = val.pow(2); ~filter.set(\amp, ~st.amp)});
	m.selectOne(
		{|val|
			1.postln;
			p.set(\preset, [\upDown, \downUp, \up, \down, \skipOne, \repeatDown][val]);
			2.postln;
			~setArp.value; },
		[0,1,2,8,9,10], {~stopArp.value}, nil
	);
	m.selectOne({|val| ~st.currentWave = val}, [3,4,11,12]);
	//m.pads[16].set({m.keys.susOn}, {m.keys.susOff}, \toggle);
	m.pads[16].set({~st.latchOn = true; m.keys.setLatch(true)}, {~st.latchOn = false; m.keys.setLatch(false)}, \toggle);
	m.pads[17].set({~setDelay.value}, {~stopDelay.value}, \toggle);
	m.transport[2].set({
		var time=List[];
		m.switchScene(1, nil!18);
		~displayNum.value(~st.bpm);
		m.pads[17].set({
		time.add(Date.getDate.rawSeconds);
			if (time.size>=3) {
				~st.bpm=(60/((time.last-time.first)/(time.size-1))).round(0.01).clip(1, 320);
				~st.bpm.postln;
				p.set(\bpm, ~st.bpm);
				if (~delay.notNil) {~delay.set(\time, ~st.bpm.bpmms*0.75)};
			};
			~displayNum.value(~st.bpm);
	})}, {
		m.switchScene(0);
	});

	~displayNum = {|num|
		var bigDigits = (num/20).asInt, smallDigits = (num - (bigDigits*20)).linlin(0,20, 0, 6).asInt;
		16.do({|i| m.pads[i].setColor(\black)});
		bigDigits.do({|i|
			m.pads[i].setColor(\redhi);
		});
		m.pads[bigDigits].setColor([\black, \yellowlo, \yellowhi, \amber, \greenlo, \greenhi, \redlo][smallDigits]);
	};

	// presets ------------------------------
	~storePresets = {
	m.switchScene(1,
		Array.fill(16, {|i|
			[{~storePreset.value(i); m.pads[i].colorOff = \redlo}, {}, \momentary, \off, \redhi,
				if (~presets[i].isNil) {\black} {if (i==~currentPreset) {\greenlo} {\redlo}}];
		});
	);
	};
	~storePreset = {|index|
		var file;
		~st.arp = p.getState;
		~st.lk = m.getScene(0);
		~presets[index] = ~st.deepCopy;
		~currentPreset = index;
		file = File.open(~path++"presets.scd", "w");
		file.write(~presets.asCompileString);
		file.close;
	};
	~loadPresets = {
		m.switchScene(1,
			Array.fill(16, {|i|
				[{~loadPreset.value(i); m.pads[i].colorOff = \greenlo}, {}, \momentary, \off, \greenhi,
					if (~presets[i].isNil) {\black} {if (i==~currentPreset) {\greenlo} {\yellowlo}}];
			});
		);
	};
	~loadPreset = {|index|
		~st = ~presets[index].deepCopy;
		~currentPreset = index;
		p.setState(~st.arp);
		//	p.setFunc(~st.playFunc, ~st.stopFunc);
		m.setSceneOffline(0, ~st.lk);
		~filter.set(\lpf, ~st.lpf );
		~filter.set(\rlpf, ~st.rlpf );
		//	~filter.set(\amp, ~st.amp);
		if (~st.latchOn) {m.keys.setLatch(true)} {m.keys.setLatch(false)};
		if (~st.arpOn) {~setArp.value} {~stopArp.value};
		if (~st.delayOn) {~setDelay.value} {~stopDelay.value};
		~updateDelay.value;

	};
	m.transport[0].set({~storePresets.value}, {m.switchScene(0)});
	m.transport[1].set({~loadPresets.value}, {m.switchScene(0)});


};


{
	var c;
	Server.local.options.sampleRate=48000;
	s.bootSync(c);
	~path = ~path ? "/Users/tomerbaruch/Music/SuperCollider/MegazordSynth/";
	~waveTables=(~path++"AKWF_nes/*").pathMatch.collect({|file| Buffer.read(s, file)});

	SynthDef(\wavetab1, {|rate=1, gate=1, bufnum, amp=0.2|
		Out.ar(0, PlayBuf.ar(1, bufnum, rate, loop:1)*EnvGen.kr(Env.adsr(0.01, 0, 1, 0.1), gate, doneAction:2)*amp)}
	).add;

	SynthDef(\wavetab4, {|rate=1, gate=1, bufnum=#[0,1,2,3], amps=#[1, 1, 1, 1]|
		var signal = Mix(Array.fill(4, {|i| PlayBuf.ar(1, bufnum[i], rate, loop:1)*amps[i]}));
		var env = EnvGen.kr(Env.adsr(0.01, 0, 1, 0.1), gate, doneAction:2);
		Out.ar(0, signal*env)}
	).add;

	SynthDef(\filter, {|bus = 0, hpf = 100, rhpf = 1, lpf = 10000, rlpf = 1, amp=1|
		var signal = In.ar(bus, 1);
		signal = RHPF.ar(RLPF.ar(signal, lpf, rlpf), hpf, rhpf);
	ReplaceOut.ar(bus, signal*amp!2);
	}).add;

	SynthDef(\stDelay, {|bus = 0, mix = 0.3, repeat = 0.6, time = 0.33, spread = 1, gate = 1|
		var inputDry,inputWet,fbLoopIn,fbLoopOut,processingL,processingR,timeLag=time, env;
		var fbNode=LocalIn.ar(1), mono;
		env=EnvGen.kr(Env.adsr(0,0,1,1),gate,doneAction:2);
		inputDry=Mix.ar(In.ar(bus,2));
		inputWet=DelayN.ar(inputDry,5,time,1);
		fbLoopIn=DelayN.ar(fbNode, 5, time)*repeat;
		processingL=(inputWet+LeakDC.ar(fbLoopIn)).tanh;
		processingR=LeakDC.ar(DelayN.ar(processingL,5,time,repeat)).tanh;
		LocalOut.ar(processingR);
		mono = Mix([processingL, processingR])!2;
		Out.ar(bus,(([processingL,processingR]*spread)+(mono*(1-spread)))*env*mix);
	}).add;

	n=nil!127;
	m=LaunchKeyMapper.new;
	~st=(
		jitter: 0.01,
		currentWave: 0,
		bpm: 160,
		lpf: 10000,
		rlpf: 1,
		amp: 0.5,
		delayMix: 0.3,
		delayRepeat: 0.4,
		delaySpread: 1,
		latchOn: false,
		delayOn: false,
		arpOn: false;

	);
	//~amps=[0.25,0,0.5,1];
	~playFunc = {|note| Synth(\wavetab1, [\bufnum, ~waveTables[~st.currentWave], \rate, (note-50).midiratio*rrand(1-~st.jitter, 1+~st.jitter)*0.91875, \amp, 0.3])};
	~stopFunc = {|note| note.set(\gate, 0); nil};
	~beats = [2, 1.5, 1, 0.75, 2/3, 0.5, 1/3, 1/4, 1/5, 1/6, 1/8, 1/10, 1/12, 1/16, 1/24, 1/32];
	~filter.free;
	~filter = Synth.tail(s, \filter, [\bus, 0, \lpf, ~st.lpf, \rlpf, ~st.rlpf, \amp, ~st.amp]);
	p = Arp1(~playFunc, ~stopFunc, ~st.bpm, 1/8, 0.5, 1);
	s.sync(c);
	1.yield;
	~currentPreset=nil;
	if (File.exists(~path++"presets.scd")) {~presets = (~path++"presets.scd").loadPaths[0]} {~presets = nil!16};
	~setControls.value;
}.fork;
)
// Dependencies:
// LaunchkeyMapper - updated LKKeys and LaunchkeyMapper
// ArrayMethods
// Arp1
