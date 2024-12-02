# microscopes-seqsr
## Sequential Super-Resolution Microscope
The sequential super-resolution microscope is a custom-built multi-target super-resolution imaging system utilizing the sequential imaging strategy. This microscope is optimized for using photo-physical properties of the fluorophore ‘Alexa Fluor 647’ for each of the multiple targets being imaged, and images are recorded using a high quantum efficiency digital CMOS camera. This microscope is also equipped with automated re-finding of once registered cells and active image stabilization for nanometer scale drift correction while imaging. Computer control of the instrument is done using custom written MATLAB software. 
```
MIC_SEQ_SRcollect();
% REQUIRES:
%   Matlab 2014b or higher
%   matlab-instrument-control (MIC) classes
```
MIC_SEQ_SRcollect is a super resolution data collection software. The super resolution data collection class for Sequential microscope works with Matlab Instrument Control (MIC) classes [give link to mic]

## Equipment List
### Microscope body
- Home built base.
- Thorlabs, MAX381/M, 3-Axis NanoMax stage, travel 4 mm with stepper motor and 20 $\mathrm{\mu m}$ with piezo.
### Objective
- Olympus, UPLSAPO 100XS, silicone oil Immersion, NA 1.35, WD 0.2 mm, FN 22.
### Cameras
- Hamamatsu, C11440-22CU, sCMOS camera, 2048x2048 pixels, pixel size 6.5 $\mathrm{\mu m}$.
### Illumination
- MPB Communications, 2RU-VFL-P-500-647-B1R, 647 nm laser, 500 mW.
- Thorlabs, DL5146-101S, 405 nm laser, 40 mW.
- Thorlabs, M660L3, 660 nm LED, 640 mW, for bright field illumination.
### Other equipments
- National Instrument, USB-6008, DAQ card.
### Filters
- Semrock, Di02-R635, dichroic mirror
- Semrock, FF01-708/75-25-D, band pass filter.

## Sequential Super-Resolution Microscope Setup Guide
For setting up the sequential super-resolution microscope for data collection, Follow the steps in the order listed below:

#### Note: 
To ensure proper initialization and safety, start with every individual component of the microscope turned off.

1. **Turn ON the Power for Stepper Motor Controller**
   - Turn ON the power switch of the three-channel bench top stepper motor controller. The switch is located at the back.

2. **Power ON the Camera**
   - Power ON the camera using the power switch on the rear face of the camera.

3. **Power ON the 647nm Laser Control Module**
   - Power ON the 647nm laser control module. The power switch is located on the front face. 
   - **Important**: Do not turn the ‘key’ to ‘Laser ON’ at this stage. This will be done after loading the sample and closing the box.

4. **Open Thorlabs Kinesis Software**
   - Locate the Kinesis software icon on the desktop and double-click to open.

5. **Check for Stepper Motors in Kinesis**
   - Verify if the stepper motors are loaded in the Kinesis software. If not, use the ‘Load’ option to gain control of the stepper motors.

6. **Home Each Stepper Motor**
   - In the Kinesis software, press the ‘Home’ button for one of the stepper motors (X, Y, or Z).
   - Observe and make sure that the corresponding stepper motor on the microscope stage is moving correctly (first forward and then in reverse). At the end of this process the display on the Kinesis control of the stepper motor should read ‘0.00 mm’ and ‘Homed’ displayed on the right/top side of the panel near to a green button.

7. **Repeat Homing for Remaining Motors**
   - Repeat the homing process for the other two stepper motors (step 6).

8. **Close Kinesis Software**

9. **Power ON the Extension Power Strip**
   - Go to the back of the optical table, and turn on the extension power strip, ensuring that all piezo and strain-gauge controllers are powered ON.
   - **Note**: These controllers should be powered ON only after the Kinesis software has been closed.

10. **Turn ON Laser Speckle Reducer**
    - For uniform laser illumination, turn on the switch at the bottom of the speckle reducer.

11. **Open MATLAB and Load Microscope Control Software**
    - Open MATLAB, and execute the following command to load the sequential microscope control software:
      ```matlab
      SEQ = MIC_SEQ_SRcollect();
      ```

12. **Verify Initialization of Controllers**
    - Confirm that all piezo/strain-gauge controllers have initialized correctly and are displaying the desired values.
    - If any controller is not initialized correctly, use the ‘Reconnect Piezos’ button on the control GUI to initialize them one-by-one. This may sometimes require power cycling the respective controllers.

13. **Ready to Load Sample and Begin Imaging**
    - Now microscope is ready for SR data collection. 

  Once you are finished using the microscope, please switch off the speckle reducer and execute the following code:  
  ```matlab
  SEQ.delete();
  ```
  Now, proceed to turn off every device except computer.

### Citation: 
[David J. Schodt, Farzin Farzam, Sheng Liu, and Keith A. Lidke, "Automated multi-target super-resolution microscopy with trust regions," Biomed. Opt. Express 14, 429-440 (2023)](https://doi.org/10.1364/BOE.477501)