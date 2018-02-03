Arp1 {
	var <>playFunc, <>stopFunc, <>bpm, <>beats, <relDur, <>octaves, <preset, <>notesFunc;
	var <>synth, <>routine, <notes, <pos=0, <calcNotes, <isRunning = false, <>presetFuncs, <>latch=false, <>safeTime = 0.02;
	var flag=false;

	*new { |playFunc, stopFunc,  bpm=120, beats=1, relDur=1, octaves=1, preset = \upDown |
		^super
		.newCopyArgs(playFunc, stopFunc, bpm, beats, relDur, octaves, preset)
		.init()
	}

	init {
		playFunc = playFunc ? {|note| Synth(\default, [\freq, note.midicps])};
		stopFunc = stopFunc ? {|synth| synth.set(\gate, 0)};
		calcNotes= [] ;
		notes = [];
		presetFuncs = (
			\upDown : {|notes, octaves|
				octaves.collect({|i| notes+(i*12)}).flatten.mirror3;
			},
			\downUp : {|notes, octaves|
				octaves.collect({|i| notes+(i*12)}).flatten.reverse.mirror3
			},
			\up : {|notes, octaves|
				octaves.collect({|i| notes+(i*12)}).flatten;
			},
			\down : {|notes, octaves|
				octaves.collect({|i| notes+(i*12)}).flatten.reverse;
			},
			\rand : {|notes, octaves|
				octaves.collect({|i| notes+(i*12)}).flatten.scramble;
			},
			\skipOne : {|notes, octaves|
				var array = octaves.collect({|i| notes+(i*12)}).flatten.mirror3;
				var size = (array.size / 3).asInt;
				size.do({|i|
					array.swap(i*3+1, i*3+2);
				});
				array;
			},
			\repeatDown : {|notes, octaves|
				var array = octaves.collect({|i| notes+(i*12)}).flatten.mirror3;
				var list = List[array[0]];
				if (array.size>1) {
					(array.size-1).do({|i|
						list.add(array[i+1]);
						list.add(array[i]);
					});
				};
				list.asArray;
			}
		);


		notesFunc = presetFuncs[preset] ? presetFuncs[\upDown];
//		("args:"++args).postln;
//		args = args ? ();
	}

	nextNote {
		^calcNotes[pos];
		//^next;
	}

	startArp {
		routine.stop;
		routine = Routine({
			var note = this.nextNote;
			//note.postln;
			isRunning = true;
			while {(note.notNil)}
			{
				var dur1 = bpm.bpmms*beats*relDur;
				var dur2 = bpm.bpmms*beats*(1-relDur);
//				Server.local.makeBundle(0.05, {synth = playFunc.value(note)});
				synth = playFunc.value(note);
				dur1.max(safeTime).wait;
//				Server.local.makeBundle(0.05, {stopFunc.value(synth)});
				stopFunc.value(synth);
				dur2.max(0).wait;
				pos = (pos + 1)%calcNotes.size;
				note = this.nextNote;
				//note.postln;
			};
//			"out".postln;
			isRunning = false;
		}).play;
	}

	stop {
		routine.stop;
		flag=true;
		{
			0.05.yield;
			stopFunc.value(synth);
			flag=false;
		}.fork;
		isRunning = false;
	}

	reCalcNotes {
		if ((notes.notNil) && (notes.size>0)) {
			calcNotes = notesFunc.value(notes, octaves);
		} { calcNotes = [] }
	}

	play { |notes_|
		if (flag==false) {
			notes = notes_;
		//	if ((notes.isNil) || (notes.size == 0)) {
		//		this.stop;
		//	} {
			this.reCalcNotes;
			if (isRunning == false) {pos = 0; this.startArp}
		//	}
		}
	}

	set { |key, val|
		switch (key)
		{\bpm} {bpm = val}
		{\beats} {beats = val}
		{\octaves} {octaves = val; this.reCalcNotes }
		{\dur} {relDur = val}
		{\notesFunc} {notesFunc = val; this.reCalcNotes; preset=nil; }
		{\preset} {
			preset = val;
			if (preset.notNil) {
				notesFunc = presetFuncs[preset] ? presetFuncs[\upDown];
				this.reCalcNotes
			}
		};
		//		{\notesFuncPreset} {notesFunc = notesFuncPresets[preset.min(notesFuncPresets.size-1)]}

	}
	setFunc {|playFunc_, stopFunc_|
		playFunc = playFunc_ ? playFunc;
		stopFunc = stopFunc_ ? stopFunc;
	}

	getState {
		^(bpm: bpm, beats: beats, octaves: octaves, dur: relDur, notesFunc: notesFunc, preset: preset)
	}

	setState { arg state;
		state.pairsDo({|key, value| this.set(key, value) });
	}

	free {
		routine.stop;
		synth.free;

	}
}




