# MegazordSynth
A wavetable synth based on NES waveforms and an arpeggiator suitable to run on a Raspberry Pi with Supercollider and PiSound.

The NES waveforms were sampled by Adventure Kid: https://www.adventurekid.se/akrt/waveforms/akwf-nes-8-bit-free/

This synth requires a Novation Launchkey Mini in order to run. 

Please download the Novation Launchkey Extension and place it in your Supercollider Extensions folder:
https://github.com/baruchtomer/NovationLaunchSeries

Then download the current repository and move the files inside "Extensions" into your Supercollider Extensions folder.

To run this you need to set the ~path variable to the current working folder of the program. 
It can be done either by changing the ~path inside the megazord-synth.scd or by creating another file which set up ~path and calls megazord-synth.scd

The content of that file should look like this:

(
~path = "/Users/tomerbaruch/Music/SuperCollider/MegazordSynth/"; //for example

(~path++"megazord-synth.scd").loadPaths;

)