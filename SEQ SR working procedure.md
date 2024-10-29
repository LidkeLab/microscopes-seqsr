# Sequential Imaging Microscope Setup Guide
_Last updated: 26 October 2024_

This guide outlines the steps for turning on the sequential imaging microscope. To ensure proper initialization and safety, start with every individual component of the microscope turned off. Follow the steps in the order listed below.

---

## Startup Procedure

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
