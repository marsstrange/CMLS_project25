(
// Boot the server first
s.boot;

// Create a simple synth definition
SynthDef(\shapeSound, { |freq=440, amp=0.1, dur=0.5, pan=0|
    var env = Env.perc(0.01, dur).kr(2);
    var sig = SinOsc.ar(freq) * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;

// Main OSC receiver with proper message parsing
OSCdef(\shapeReceiver, { |msg|
    var category, x, y, width, height, r, g, b, pressure;
    var freq, amp, dur, pan;

    // Properly unpack the message array
    category = msg[1].asString;
    x = msg[2].asFloat;
    y = msg[3].asFloat;
    width = msg[4].asFloat;
    height = msg[5].asFloat;
    r = msg[6].asFloat;
    g = msg[7].asFloat;
    b = msg[8].asFloat;
    pressure = msg[9].asFloat;

    // Debug prints
    postln("----------------------");
    postf("Shape: %\n", category);
    postf("Position: (%, %)\n", x, y);
    postf("Size: % x %\n", width, height);
    postf("Color: (%, %, %)\n", r, g, b);
    postf("Pressure: %\n", pressure);

    // Convert parameters to sound with safety checks
    freq = y.clip(0, 1).linexp(0, 1, 100, 2000);
    amp = pressure.clip(0, 1) * 0.2;
    dur = width.clip(0, 1000).linexp(0, 1000, 0.1, 2);
    pan = x.clip(0, 1).linlin(0, 1, -1, 1);

    postf("Sound params - Freq: %, Amp: %, Dur: %, Pan: %\n", freq, amp, dur, pan);

    Synth(\shapeSound, [
        \freq, freq,
        \amp, amp,
        \dur, dur,
        \pan, pan
    ]);
}, '/shape');
)