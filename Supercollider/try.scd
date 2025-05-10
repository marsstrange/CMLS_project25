// Boot the server first
s.boot;

// SynthDef with all waveform options
SynthDef(\shapeSound, { |freq=440, amp=0.1, dur=0.5, pan=0, waveType=0, total_length=1|
    var env = Env.perc(0.01, dur * total_length.clip(0.1, 2)).kr(2); // Scale duration by total_length
    var sig;

    // Waveform selector:
    // 0 = Sine (circle/default)
    // 1 = Square (rectangle)
    // 2 = Triangle (triangle)
    // 3 = Sawtooth (line)
    sig = Select.ar(waveType, [
        SinOsc.ar(freq),            // Sine
        LFPulse.ar(freq),           // Square
        LFTri.ar(freq),             // Triangle
        Saw.ar(freq)                // Sawtooth
    ]);

    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;

// OSC receiver with total_length support
OSCdef(\shapeReceiver, { |msg|
    var category, x, y, width, height, r, g, b, pressure, total_length;
    var freq, amp, dur, pan, waveType;

    // Unpack the message (now includes total_length)
    category = msg[1].asString.toLower;
    x = msg[2].asFloat;
    y = msg[3].asFloat;
    width = msg[4].asFloat;
    height = msg[5].asFloat;
    r = msg[6].asFloat;
    g = msg[7].asFloat;
    b = msg[8].asFloat;
    pressure = msg[9].asFloat;
    total_length = msg[10].asFloat; // Added parameter

    // Debug prints
    postln("----------------------");
    postf("Shape: %\n", category);
    postf("Position: (%, %)\n", x, y);
    postf("Size: % x %\n", width, height);
    postf("Color: (%, %, %)\n", r, g, b);
    postf("Pressure: %\n", pressure);
    postf("Total Length: %\n", total_length);

    // Sound parameter mapping
    freq = y.clip(0, 1).linexp(0, 1, 100, 2000);
    amp = pressure.clip(0, 1) * 0.2;
    dur = total_length/100;
    pan = x.clip(0, 1).linlin(0, 1, -1, 1);

    // Shape → Waveform mapping
    waveType = case
        { category.contains("triangle") } { 2 }  // Triangle → LFTri
        { category.contains("rect") || category.contains("square") } { 1 }  // Rectangle → LFPulse
        { category.contains("line") } { 3 }      // Line → Saw
        { 0 };                                   // Default: circle → SinOsc

    postf("Sound params - Freq: %, Amp: %, Dur: %, Pan: %, Wave: %\n", freq, amp, dur, pan, waveType);

    Synth(\shapeSound, [
        \freq, freq,
        \amp, amp,
        \dur, dur,
        \pan, pan,
        \waveType, waveType,
        \total_length, total_length  // Passed to Env.perc for duration scaling
    ]);
}, '/shape');