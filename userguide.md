# Sequential Super-Resolution Microscope User Guide

This guide covers the complete workflow for operating the sequential super-resolution microscope, from power-on through data collection and shutdown.

## Startup

Start with all microscope components powered off.

1. **Turn ON the stepper motor controller** (power switch on the back of the three-channel benchtop controller).
2. **Turn ON the camera** (power switch on rear face).
3. **Turn ON the 647nm laser control module** (front face switch). Do **not** turn the key to "Laser ON" yet — this is done after loading the sample and closing the box.
4. **Turn ON the extension power strip** at the back of the optical table. This powers the piezo and strain-gauge controllers.
5. **Turn ON the laser speckle reducer** (switch at the bottom).
6. **Start the MATLAB control software:**
   ```matlab
   SEQ = MIC_SEQ_SRcollect();
   ```
   The software will connect to the stepper motors and move the stage to a safe position. If it asks "Is the sample fixed on the stage?" answer **No** for a normal startup.
7. **Home steppers if prompted** — if the stepper controller was power cycled, the software will detect that all positions are at zero and show a dialog asking whether to home the motors. Click **Home** to proceed (no sample must be loaded). Homing progress is printed to the MATLAB command window — confirm all three axes report "done" before continuing. You can also home manually at any time with `SEQ.homeSteppers()`.
8. **Verify initialization** — confirm all piezo/strain-gauge controllers display the expected values. If any controller failed to initialize, use the **Reconnect Piezos** button on the GUI.

### Recovering from a crash

If MATLAB crashed while a sample was loaded, the stage may still be close to the objective. On the next startup, answer **Yes** to "Is the sample fixed on the stage?" The software will raise the stage to a safe position and prompt you to remove the sample before continuing with normal setup.

If the stepper controller was also power-cycled during the crash, the software cannot safely raise the stage. In that case, physically remove the sample before restarting.

## Loading a Sample

1. Place the coverslip with the sample on the stage.
2. Press **Load Sample** on the GUI. The stepper moves Z down to the `CoverslipZPosition` (default 1.5mm) and centers the piezos.
3. **Close the enclosure box**, then turn the 647nm laser key to "Laser ON".

### Finding the coverslip

After loading the sample, you need to find the coverslip surface:

1. Press **Find Coverslip** on the GUI. This starts a live full-frame camera view with 660nm lamp illumination.
2. Use the **stepper Z buttons** (large steps ~50 µm) to move the stage until you see the coverslip surface come into focus. You are looking for the interface between the coverslip and the sample — features like cells or debris should become visible.
3. Once you can see the surface, use **small stepper steps** (~2 µm) and the **mouse scroll wheel** (piezo Z) to fine-tune the focus.
4. Close the focus window when done.

The `CoverslipZPosition` property stores the expected Z position of the coverslip. If the coverslip is consistently at a different Z position, update this value so that **Load Sample** brings the stage closer to focus on the first try.

## Setting Up Save Directories

Before selecting cells, configure the save locations on the GUI:

1. Set **TopDir** to the root directory where all data will be saved (e.g. `Y:\Data` or `C:\Users\kalidke\Documents\Data`).
2. Set **CoverslipName** to an identifier for this coverslip/experiment (e.g. `CS01_AF647_tubulin`). Data will be saved under `TopDir/CoverslipName/`.
3. Optionally set **FilenameTag** to add a suffix to data filenames.

Reference images, sequence data, and metadata are all saved relative to these directories. If they are not set, files will be saved in the current MATLAB working directory.

## Finding and Selecting Cells

Cell selection uses a 10x10 grid system. Each grid button on the GUI corresponds to a region of the coverslip.

### Navigating the grid

1. Set the **Grid Corner** position (mm) to define where the 10x10 grid starts on the coverslip.
2. Click a grid button (numbered 1–100) in the **ROI Selection Tool** panel. This calls `exposeGridPoint`: the stage moves to that grid position, takes a full-frame brightfield image with the 660nm lamp, and displays it.
3. **Click on a cell** in the displayed image. The stage moves to center that cell in the field of view.

### Selecting a cell

After clicking a cell in the grid image, `exposeCellROI` runs automatically:
1. A zoomed ROI image is captured and displayed.
2. **Click on the cell** to fine-center it.
3. The lamp focus mode starts so you can adjust the Z focus using the stepper/piezo controls or mouse scroll wheel.

### Saving a reference image

Once a cell is centered and focused, press **Save Reference** on the GUI. This:
- Collects a Z-stack for brightfield registration (if `UseBrightfieldReg` is enabled).
- Captures a full-frame reference image.
- Records the current stepper and piezo positions.
- Saves everything to a `Reference_Cell_XX.mat` file in the `TopDir/CoverslipName/` directory.

The cell counter increments after each saved reference. Repeat the grid navigation and cell selection process for all cells you want to image.

## Focusing

Several focus modes are available via GUI buttons:

- **Lamp Focus** — streams the camera with 660nm lamp illumination at the collection ROI. Use for coarse focusing and finding the coverslip surface.
- **Laser Focus Low** — streams with the 647nm laser at low power through the ND filter. Use for finding fluorescent features.
- **Laser Focus High** — streams with the 647nm laser at high power without the ND filter. Use to verify signal before acquisition.
- **Find Coverslip** — displays the full camera ROI with 660nm lamp. Use when initially placing the sample to locate the coverslip surface.

### Stage controls

- **Mouse scroll wheel**: fine Z piezo adjustment.
- **Stepper buttons** on the GUI: large steps (~50 µm) and small steps (~2 µm) in Z.
- **Piezo buttons**: fine Z adjustments (~100 nm).

## Configuring Acquisition Parameters

Key parameters adjustable from the GUI:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `NumberOfFrames` | 6000 | Frames per sequence |
| `NumberOfSequences` | 10 | Number of sequences per cell |
| `NAcquisitionCycles` | 1 | Number of full acquisition cycles |
| `ExposureTimeSequence` | 0.04 s | Exposure time during acquisition |
| `LaserPowerSequence647` | 150 | 647nm laser power during acquisition |
| `LaserPowerSequence405` | 2 | 405nm laser power during acquisition |
| `UsePreActivation` | 1 | Excite fluorophores before acquiring |
| `DurationPreActivation` | 10 s | Duration of pre-activation |
| `StabPeriod` | 5 s | Time between stabilization events |
| `UseBrightfieldReg` | checkbox | Enable brightfield registration for drift correction |
| `SaveFileType` | 'h5DataGroups' | HDF5 file format ('h5' or 'h5DataGroups') |

## Automated Data Collection

Once all cells have been selected and their references saved:

1. Set the desired acquisition parameters.
2. Press **Auto Collect** on the GUI. You will be prompted to select the directory containing the `Reference_Cell_XX.mat` files.
3. The software loops through each cell:
   - Moves to the saved stepper position.
   - Performs brightfield registration to re-find the cell (if enabled).
   - Runs pre-activation (if enabled).
   - Acquires the configured number of sequences, saving frames to an HDF5 file.
   - Performs periodic stabilization during acquisition.
4. After all cells are imaged, the laser and shutter are turned off automatically.

### Aborting

Press **Abort** on the GUI to stop acquisition after the current sequence finishes.

## Sequential Multi-Target Imaging

The sequential imaging workflow images multiple targets on the same cells using the same Alexa Fluor 647 fluorophore:

1. **Round 1**: Select cells, save references, run Auto Collect.
2. **Photobleach/quench**: Bleach the current label. The `IsBleach` flag can be set for photobleach rounds.
3. **Remove and relabel**: Remove the coverslip, wash, apply the next antibody-fluorophore conjugate.
4. **Remount**: Place the coverslip back on the stage.
5. **Find coverslip offset**: Use **Find Coverslip Offset** (automatic) or **Find Coverslip Offset Manual** to align the remounted coverslip with the previously saved cell positions. This uses brightfield cross-correlation to determine the XYZ offset.
6. **Round 2+**: Run Auto Collect again — the software uses the saved references plus the measured offset to re-find each cell.

Repeat for each target.

## Data Output

Data is saved as HDF5 files in the `TopDir/CoverslipName/` directory:

- **Image data**: raw uint16 frames organized by channel, Z-position, and sequence.
- **Reference files**: `Reference_Cell_XX.mat` containing brightfield reference stacks, stage positions, and metadata.
- **Metadata**: exposure times, laser powers, ROI settings, and instrument state are saved within the HDF5 file.

## Shutdown

1. Run:
   ```matlab
   SEQ.delete();
   ```
   This turns off lasers, closes the shutter, and inserts the ND filter.
2. Turn off the laser speckle reducer.
3. Turn off all hardware components (camera, laser module, stepper controller, extension power strip).

## Troubleshooting

### No fluorescence detected, but everything appears to work
The 647nm shutter may not be in remote mode. Hold the **enable** button on the shutter controller for 3 seconds to toggle between manual and remote mode.

### Fluorescence has low/high mixed up or alternates incorrectly
The flip mount was reset to the wrong mode. In Kinesis, set the flip mount to **go to position** mode (instead of toggle).

### Stepper motors not responding
Power cycle the stepper motor controller and restart `MIC_SEQ_SRcollect()`. The software will detect the power cycle and prompt you to home the motors.

### Piezo controller not initialized
Use the **Reconnect Piezos** button on the GUI to reconnect individual axes. This may require power cycling the affected controller.
