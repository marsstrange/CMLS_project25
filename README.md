- For VST in Supercollider: https://git.iem.at/pd/vstplugin/-/releases
- https://www.youtube.com/watch?v=TOKgLjix1aU


TO DO: 
1. To do a report
2. To do slides
3. To change the position of the text on vst3 plugin
4. To change directory for vst3 in SC
5. To test everything together (also with a tablet)
6. To reorganize github repo (to write a readme + reorganize the files themselves)
7. To improve sound generation if needed
8. To map vst3 to some other parameters (discussion needed)
9. h is help button in text add
10. delete z button change



Drawing Sound Project
====================

A real-time audio-visual application that converts drawings into sound using Python, SuperCollider and JUCE. 

Prerequisites
------------
- Python 3.x
- SuperCollider 3.x
- Required Python packages:
  - PyQt5
  - python-osc
  - numpy
  - opencv-python

Installation
-----------
1. Install Python dependencies:
   pip install PyQt5 python-osc numpy opencv-python

2. Install SuperCollider VSTPlugin extention from [supercollider.github.io](https://git.iem.at/pd/vstplugin/-/releases)

Running the Application
----------------------
1. Start SuperCollider first:
   - Open SuperCollider
   - Load the try.scd file
   - Run the code block by block (Select and press Ctrl+Enter or Cmd+Enter) 

2. Then run the Python application:
   python main.py

Controls
--------
- Mouse/Tablet: Draw on the canvas
- Pressure: Controls line thickness and sound amplitude
- Position: Controls sound frequency and panning
- C: Open color picker
- H: Show help menu
- Z: Clear canvas and stop all sounds
- Esc: Stop all sounds

Shape Detection
--------------
The application detects different shapes and triggers corresponding sounds:
- Lines → Sawtooth wave
- Triangles → Triangle wave
- Rectangles → Square wave
- Other shapes → Sine wave

Troubleshooting
--------------
If you encounter connection errors:
1. Make sure SuperCollider is running before starting Python
2. Check that port 57120 is available
3. If needed, restart both applications

Project Structure
----------------
- main.py: Python application with GUI and drawing functionality
- main.scd: SuperCollider code for sound synthesis
- ShimmerEffectPlugin.vst3: VST plugin for audio effects

Dependencies
-----------
Python:
- PyQt5: GUI framework
- python-osc: OSC communication
- numpy: Numerical operations
- opencv-python: Shape detection

SuperCollider:
- VSTPlugin: For audio effects
- OSC: For communication with Python
