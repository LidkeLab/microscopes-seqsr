% test_setup_piezo_z_kpc101.m
% Standalone test for a Thorlabs KPC101 (integrated K-Cube piezo + strain gauge).
%
% Why a separate file?
%   test_setup_piezo_z.m uses mic.stage3D.NanoMaxPiezos, which requires two
%   separate serial numbers per axis (TPZ001 controller + TSG001 gauge). The
%   KPC101 is a single device with one serial number and uses the unified
%   KPC_* API instead of the separate KPZ/KSG APIs. There are no MIC mex
%   files for KPC101, so this script talks to the device directly via the
%   Thorlabs Kinesis .NET CLI assembly.
%
% Hardware:
%   Thorlabs KPC101 connected to the Z piezo channel of the NanoMax 300.
%
% One-time Kinesis software setup (persist to device):
%   1. Open Kinesis, select the KPC101.
%   2. Control tab: set Loop Mode to "Closed Loop", Maximum Travel to 20 um.
%   3. Go to Startup tab and apply current settings so they survive power cycles.

SerialNo   = '113251934';  % KPC101 serial number (S/N from Kinesis panel)
KinesisDir = 'C:\Program Files\Thorlabs\Kinesis\';

%% Load Kinesis .NET assemblies
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.DeviceManagerCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.GenericPiezoCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.KCube.PiezoStrainGaugeCLI.dll']);

%% Connect to KPC101
fprintf('Building Kinesis device list...\n');
Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
pause(0.5);

fprintf('Connecting to KPC101 serial %s...\n', SerialNo);
dev = Thorlabs.MotionControl.KCube.PiezoStrainGaugeCLI.KCubePiezoStrainGauge ...
        .CreateKCubePiezoStrainGauge(SerialNo);
dev.Connect(SerialNo);

if ~dev.IsSettingsInitialized()
    dev.WaitForSettingsInitialized(5000);
end
if ~dev.IsSettingsInitialized()
    dev.Disconnect();
    error('KPC101: settings did not initialize within 5 s.');
end

dev.GetPiezoConfiguration(SerialNo);
dev.StartPolling(250);
pause(1.0);
dev.EnableDevice();
pause(0.5);

if ~dev.IsClosedLoop()
    % SetPositionControlMode requires the PiezoControlModeTypes enum, not a bare int
    modeType = dev.GetPositionControlMode().GetType();
    dev.SetPositionControlMode(System.Enum.ToObject(modeType, int32(2)));  % 2 = Closed Loop
    pause(0.5);
end
fprintf('Connected. Closed loop: %d\n', dev.IsClosedLoop());

%% Read initial position
% GetPosition() returns um directly as System.Decimal.
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
fprintf('\n=== INITIAL POSITION ===\n');
fprintf('Z = %.3f um\n', pos);

%% Move to center (10 um)
fprintf('\n=== MOVING TO CENTER (10 um) ===\n');
dev.SetPosition(System.Decimal(10.0));
pause(1.0);
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
fprintf('Position after center: Z = %.3f um\n', pos);

%% Step up +2 um
fprintf('\n=== STEP UP +2 um ===\n');
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
dev.SetPosition(System.Decimal(pos + 2.0));
pause(0.5);
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
fprintf('Position after step up: Z = %.3f um\n', pos);

%% Step down -4 um (net -2 from center)
fprintf('\n=== STEP DOWN -4 um ===\n');
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
dev.SetPosition(System.Decimal(pos - 4.0));
pause(0.5);
dev.RequestPosition(); pause(0.3);
pos = System.Decimal.ToDouble(dev.GetPosition());
fprintf('Position after step down: Z = %.3f um\n', pos);

%% Return to center
fprintf('\n=== RETURNING TO CENTER ===\n');
dev.SetPosition(System.Decimal(10.0));
pause(1.0);
dev.RequestPosition(); pause(0.3);
finalPos = System.Decimal.ToDouble(dev.GetPosition());
fprintf('Final position: Z = %.3f um\n', finalPos);

ok = abs(finalPos - 10.0) < 0.5;
if ok
    fprintf('\nSUCCESS: KPC101 Z piezo responds correctly.\n');
else
    fprintf('\nFAIL: Z piezo did not reach target (got %.3f um, expected ~10 um).\n', finalPos);
end

%% Clean up
dev.StopPolling();
dev.Disconnect();
fprintf('Connection closed.\n');
