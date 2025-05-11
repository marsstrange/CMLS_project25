s.boot;

// SynthDef with infinite sustain
SynthDef(\shapeSound, { |freq=440, amp=0.1, pan=0, waveType=0, gate=1|
	var env = Env.asr(0.01, 1, 0.3).kr(gate, doneAction: 2);
	var sig;

	sig = Select.ar(waveType, [
		SinOsc.ar(freq),    // 0 - Sine
		LFPulse.ar(freq),   // 1 - Square
		LFTri.ar(freq),     // 2 - Triangle
		Saw.ar(freq)        // 3 - Sawtooth
	]);

	sig = sig * env * amp;
	sig = Pan2.ar(sig, pan);
	Out.ar(0, sig);
}).add;

// Track last 3 active synths
~lastSynths = [];

// Main OSC receiver for shapes
OSCdef(\shapeReceiver, { |msg|
	var category, x, y, width, height, r, g, b, pressure, total_length;
	var freq, amp, pan, waveType, synth;

	category = msg[1].asString.toLower;
	x = msg[2].asFloat;
	y = msg[3].asFloat;
	width = msg[4].asFloat;
	height = msg[5].asFloat;
	r = msg[6].asFloat;
	g = msg[7].asFloat;
	b = msg[8].asFloat;
	pressure = msg[9].asFloat;
	total_length = msg[10].asFloat;

	postln("----------------------");
	postf("Shape: %\n", category);
	postf("Position: (%, %)\n", x, y);
	postf("Size: % x %\n", width, height);
	postf("Color: (%, %, %)\n", r, g, b);
	postf("Pressure: %\n", pressure);
	postf("Total Length: %\n", total_length);

	// Higher y = higher freq (corrected mapping)
	freq = y.clip(0, 1).linexp(0, 1, 100, 2000);
	amp = pressure.clip(0, 1) * 0.2;
	pan = x.clip(0, 1).linlin(0, 1, -1, 1);

	// Waveform selection
	if (category.contains("triangle")) {
		waveType = 2;
	} {
		if (category.contains("rect") or: { category.contains("square") }) {
			waveType = 1;
		} {
			if (category.contains("line")) {
				waveType = 3;
			} {
				waveType = 0; // default sine
			}
		}
	};

	postf("Sound params - Freq: %, Amp: %, Pan: %, Wave: %\n", freq, amp, pan, waveType);

	// Keep only last 3 synths
	if (~lastSynths.size >= 3) {
		~lastSynths.removeAt(0).free;
	};

	synth = Synth(\shapeSound, [
		\freq, freq,
		\amp, amp,
		\pan, pan,
		\waveType, waveType
	]);

	~lastSynths = ~lastSynths.add(synth);
}, '/shape');

// OSC command to stop all active synths
OSCdef(\stopAll, {
	"Stopping all synths".postln;
	~lastSynths.do(_.free);
	~lastSynths = [];
}, '/stopAll');
