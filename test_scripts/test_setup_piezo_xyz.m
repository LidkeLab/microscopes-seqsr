% test_setup_piezo_xyz.m
% Combined 3-axis piezo test for the NanoMax 300 stage via Kinesis .NET CLI.
% No mex files are used — all five devices are controlled through .NET directly.
%
% Axis assignment:
%   X: TPZ001 (81843229) + TSG001 (84842506)  — TCubePiezo + TCubeStrainGauge CLI
%   Y: KPZ101 (29501303) + KSG101 (59000140)  — KCubePiezo + KCubeStrainGauge CLI
%   Z: KPC101 (113251934)                      — KCubePiezoStrainGauge CLI (integrated)
%
% Position commands:
%   X, Y: SetPercentageTravel(%) — TPZ001/KPZ101 are voltage controllers with no
%          fixed um scale; position is commanded as % of max voltage range.
%          Open-loop (no SMA feedback cable fitted).
%   Z:    SetPosition(um) — KPC101 has integrated gauge + Max Travel = 20 um.
%
% Position readback:
%   X, Y: strain gauge GetReading() converted to um via (raw / 2^15 * 20)
%   Z:    KPC101 GetPosition() returns um directly
%
% Pass/fail for X and Y is a movement test (stage goes up when commanded up,
% returns close to start), not an absolute um check.
%
% Kinesis GUI setup is NOT required for X/Y: the script now forces
% Input Source = Software only and Max Output Voltage = 75 V in software
% (SetVoltageSource / SetMaxOutputVoltage), overriding any GUI/hub setting.
%   KPC101 (113251934): already configured (Closed Loop, Max Travel = 20 um).
%   Disconnect all in Kinesis before running.
%
% Note: the original mic.linearstage.TCubePiezo drove this hardware in CLOSED
% loop with strain-gauge feedback routed through the T-Cube hub ("Analogue
% channel 1"), no SMA cable. If open-loop voltage still fails, closed loop
% via hub feedback is the fallback (SetPositionControlMode(2) + SetPosition).

KinesisDir = 'C:\Program Files\Thorlabs\Kinesis\';

XCtrlSN  = '81843229';   % TPZ001 — X piezo controller
XGaugeSN = '84842506';   % TSG001 — X strain gauge
YCtrlSN  = '29501303';   % KPZ101 — Y piezo controller
YGaugeSN = '59000140';   % KSG101 — Y strain gauge
ZSerial  = '113251934';  % KPC101 — Z (integrated controller + gauge)

MAX_RETRIES  = 5;
RETRY_PAUSE  = 3.0;   % seconds between retries

%% Load .NET assemblies
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.DeviceManagerCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.GenericPiezoCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.TCube.PiezoCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.TCube.StrainGaugeCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.KCube.PiezoCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.KCube.StrainGaugeCLI.dll']);
NET.addAssembly([KinesisDir 'Thorlabs.MotionControl.KCube.PiezoStrainGaugeCLI.dll']);

fprintf('Building device list...\n');
Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
pause(3.0);

%% Connect Y axis — KSG101 strain gauge
fprintf('Connecting Y axis (KPZ101 %s + KSG101 %s)...\n', YCtrlSN, YGaugeSN);

SGy = [];
for attempt = 1:MAX_RETRIES
    try
        Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
        pause(1.0);
        SGy = Thorlabs.MotionControl.KCube.StrainGaugeCLI.KCubeStrainGauge ...
                .CreateKCubeStrainGauge(YGaugeSN);
        SGy.Connect(YGaugeSN);
        break;
    catch e
        fprintf('  KSG101 attempt %d/%d failed: %s\n', attempt, MAX_RETRIES, char(e.message));
        if attempt < MAX_RETRIES
            pause(RETRY_PAUSE);
        else
            error('Could not connect to KSG101 (%s) after %d attempts.', YGaugeSN, MAX_RETRIES);
        end
    end
end
if ~SGy.IsSettingsInitialized(); SGy.WaitForSettingsInitialized(5000); end
SGy.GetStrainGaugeConfiguration(YGaugeSN);
SGy.StartPolling(250); pause(0.5);
SGy.EnableDevice(); pause(0.5);

%% Connect Y axis — KPZ101 piezo controller
PY = [];
for attempt = 1:MAX_RETRIES
    try
        Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
        pause(1.0);
        PY = Thorlabs.MotionControl.KCube.PiezoCLI.KCubePiezo.CreateKCubePiezo(YCtrlSN);
        PY.Connect(YCtrlSN);
        break;
    catch e
        fprintf('  KPZ101 attempt %d/%d failed: %s\n', attempt, MAX_RETRIES, char(e.message));
        if attempt < MAX_RETRIES
            pause(RETRY_PAUSE);
        else
            error('Could not connect to KPZ101 (%s) after %d attempts.', YCtrlSN, MAX_RETRIES);
        end
    end
end
if ~PY.IsSettingsInitialized(); PY.WaitForSettingsInitialized(5000); end
PY.GetPiezoConfiguration(YCtrlSN);
PY.StartPolling(250); pause(1.0);
PY.EnableDevice(); pause(0.5);

% Same input-source / max-voltage forcing as X (see comments there).
try
    srcTypeY = PY.GetVoltageSource().GetType();
    PY.SetVoltageSource(System.Enum.ToObject(srcTypeY, int32(0))); pause(0.3);
    fprintf('Y voltage source set to Software only (was %d)\n', int32(PY.GetVoltageSource()));
catch e
    fprintf('Y SetVoltageSource skipped: %s\n', char(e.message));
end
try
    PY.SetMaxOutputVoltage(System.Decimal(75.0)); pause(0.3);
catch e
    fprintf('Y SetMaxOutputVoltage skipped: %s\n', char(e.message));
end
fprintf('Y max output voltage: %.2f V\n', System.Decimal.ToDouble(PY.GetMaxOutputVoltage()));

modeTypeY = PY.GetPositionControlMode().GetType();
PY.SetPositionControlMode(System.Enum.ToObject(modeTypeY, int32(1))); pause(0.5);  % 1 = Open Loop
PY.SetOutputVoltage(System.Decimal(0.0)); pause(0.5);  % start from 0 V
% KCubePiezo has no RequestOutputVoltage (polling covers it); TCubePiezo needs it
try PY.RequestOutputVoltage(); catch; end; pause(0.3);
fprintf('Y ready. Mode=%d, Voltage=%.2f V\n', int32(PY.GetPositionControlMode()), ...
    System.Decimal.ToDouble(PY.GetOutputVoltage()));

%% Connect Z axis — KPC101 (integrated)
fprintf('Connecting Z axis (KPC101 %s)...\n', ZSerial);

PZ = [];
for attempt = 1:MAX_RETRIES
    try
        Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
        pause(1.0);
        PZ = Thorlabs.MotionControl.KCube.PiezoStrainGaugeCLI.KCubePiezoStrainGauge ...
                .CreateKCubePiezoStrainGauge(ZSerial);
        PZ.Connect(ZSerial);
        break;
    catch e
        fprintf('  KPC101 attempt %d/%d failed: %s\n', attempt, MAX_RETRIES, char(e.message));
        if attempt < MAX_RETRIES
            pause(RETRY_PAUSE);
        else
            error('Could not connect to KPC101 (%s) after %d attempts.', ZSerial, MAX_RETRIES);
        end
    end
end
if ~PZ.IsSettingsInitialized(); PZ.WaitForSettingsInitialized(5000); end
PZ.GetPiezoConfiguration(ZSerial);
PZ.StartPolling(250); pause(1.0);
PZ.EnableDevice(); pause(0.5);
if ~PZ.IsClosedLoop()
    modeTypeZ = PZ.GetPositionControlMode().GetType();
    PZ.SetPositionControlMode(System.Enum.ToObject(modeTypeZ, int32(2))); pause(0.5);  % 2 = Closed Loop
end
fprintf('Z ready. Closed loop: %d\n', PZ.IsClosedLoop());

%% Connect X axis — TSG001 strain gauge (connected last: T-cubes are the
%% slowest to enumerate; Y and Z connecting first confirms they are fine)
fprintf('Connecting X axis (TPZ001 %s + TSG001 %s)...\n', XCtrlSN, XGaugeSN);

SGx = [];
for attempt = 1:MAX_RETRIES
    try
        Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
        pause(2.0);
        SGx = Thorlabs.MotionControl.TCube.StrainGaugeCLI.TCubeStrainGauge ...
                .CreateTCubeStrainGauge(XGaugeSN);
        SGx.Connect(XGaugeSN);
        % T-cubes report "Device not ready" for a while even after Connect
        % succeeds — settings init must be inside the retry loop too.
        if ~SGx.IsSettingsInitialized(); SGx.WaitForSettingsInitialized(10000); end
        SGx.GetStrainGaugeConfiguration(XGaugeSN);
        break;
    catch e
        fprintf('  TSG001 attempt %d/%d failed: %s\n', attempt, MAX_RETRIES, char(e.message));
        try SGx.Disconnect(); catch; end
        if attempt < MAX_RETRIES
            pause(RETRY_PAUSE);
        else
            error('Could not connect to TSG001 (%s) after %d attempts.', XGaugeSN, MAX_RETRIES);
        end
    end
end
SGx.StartPolling(250); pause(0.5);
SGx.EnableDevice(); pause(0.5);

%% Connect X axis — TPZ001 piezo controller
PX = [];
for attempt = 1:MAX_RETRIES
    try
        Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();
        pause(2.0);
        PX = Thorlabs.MotionControl.TCube.PiezoCLI.TCubePiezo.CreateTCubePiezo(XCtrlSN);
        PX.Connect(XCtrlSN);
        if ~PX.IsSettingsInitialized(); PX.WaitForSettingsInitialized(10000); end
        PX.GetPiezoConfiguration(XCtrlSN);
        break;
    catch e
        fprintf('  TPZ001 attempt %d/%d failed: %s\n', attempt, MAX_RETRIES, char(e.message));
        try PX.Disconnect(); catch; end
        if attempt < MAX_RETRIES
            pause(RETRY_PAUSE);
        else
            error('Could not connect to TPZ001 (%s) after %d attempts.', XCtrlSN, MAX_RETRIES);
        end
    end
end
PX.StartPolling(250); pause(1.0);
PX.EnableDevice(); pause(0.5);

% Force input source = Software only. If the device is set to follow the hub
% analogue channel / external SMA, software voltage commands are ignored.
try
    srcTypeX = PX.GetVoltageSource().GetType();
    PX.SetVoltageSource(System.Enum.ToObject(srcTypeX, int32(0))); pause(0.3);
    fprintf('X voltage source set to Software only (was %d)\n', int32(PX.GetVoltageSource()));
catch e
    fprintf('X SetVoltageSource skipped: %s\n', char(e.message));
end

% SetOutputVoltage is clamped to MaxOutputVoltage — if this setting never
% initialized on the device it can be 0, silently clamping every command to 0 V.
try
    PX.SetMaxOutputVoltage(System.Decimal(75.0)); pause(0.3);
catch e
    fprintf('X SetMaxOutputVoltage skipped: %s\n', char(e.message));
end
fprintf('X max output voltage: %.2f V\n', System.Decimal.ToDouble(PX.GetMaxOutputVoltage()));

modeTypeX = PX.GetPositionControlMode().GetType();
PX.SetPositionControlMode(System.Enum.ToObject(modeTypeX, int32(1))); pause(0.5);  % 1 = Open Loop
PX.SetOutputVoltage(System.Decimal(0.0)); pause(0.5);  % start from 0 V
try PX.RequestOutputVoltage(); catch; end; pause(0.3);   % GetOutputVoltage is stale without an explicit request
fprintf('X ready. Mode=%d, Voltage=%.2f V\n', int32(PX.GetPositionControlMode()), ...
    System.Decimal.ToDouble(PX.GetOutputVoltage()));

%% Helper: raw strain gauge count -> um  (15-bit over 20 um range)
sgToUM = @(raw) System.Decimal.ToDouble(raw) / 2^15 * 20;

%% Initial positions
fprintf('\n=== INITIAL POSITIONS ===\n');
SGx.RequestReading(); SGy.RequestReading(); PZ.RequestPosition(); pause(0.4);
x = sgToUM(SGx.GetReading());
y = sgToUM(SGy.GetReading());
z = System.Decimal.ToDouble(PZ.GetPosition());
fprintf('X = %.3f um\nY = %.3f um\nZ = %.3f um\n', x, y, z);

% Open-loop voltage targets for X and Y (TPZ001/KPZ101 max = 75 V):
%   center = 37.5 V (50%), up = 52.5 V (70%), down = 22.5 V (30%)
vCenter = System.Decimal(37.5);
vUp     = System.Decimal(52.5);
vDown   = System.Decimal(22.5);

%% Move all axes to center (37.5 V for X/Y, 10 um for Z)
fprintf('\n=== MOVING TO CENTER (X/Y: 37.5 V, Z: 10 um) ===\n');
PX.SetOutputVoltage(vCenter);
PY.SetOutputVoltage(vCenter);
PZ.SetPosition(System.Decimal(10.0));
pause(1.5);
try PX.RequestOutputVoltage(); catch; end
try PY.RequestOutputVoltage(); catch; end
pause(0.3);
fprintf('X voltage readback: %.2f V\n', System.Decimal.ToDouble(PX.GetOutputVoltage()));
fprintf('Y voltage readback: %.2f V\n', System.Decimal.ToDouble(PY.GetOutputVoltage()));
SGx.RequestReading(); SGy.RequestReading(); PZ.RequestPosition(); pause(0.4);
xCenter = sgToUM(SGx.GetReading());
yCenter = sgToUM(SGy.GetReading());
z       = System.Decimal.ToDouble(PZ.GetPosition());
fprintf('X = %.3f um\nY = %.3f um\nZ = %.3f um\n', xCenter, yCenter, z);

%% Step all axes up (X/Y: 52.5 V, Z: +2 um)
fprintf('\n=== STEP UP (X/Y: 52.5 V, Z: 12 um) ===\n');
PX.SetOutputVoltage(vUp);
PY.SetOutputVoltage(vUp);
PZ.SetPosition(System.Decimal(12.0));
pause(0.8);
try PX.RequestOutputVoltage(); catch; end
try PY.RequestOutputVoltage(); catch; end
pause(0.3);
fprintf('X voltage readback: %.2f V\n', System.Decimal.ToDouble(PX.GetOutputVoltage()));
fprintf('Y voltage readback: %.2f V\n', System.Decimal.ToDouble(PY.GetOutputVoltage()));
SGx.RequestReading(); SGy.RequestReading(); PZ.RequestPosition(); pause(0.4);
xUp = sgToUM(SGx.GetReading());
yUp = sgToUM(SGy.GetReading());
zUp = System.Decimal.ToDouble(PZ.GetPosition());
fprintf('X = %.3f um\nY = %.3f um\nZ = %.3f um\n', xUp, yUp, zUp);

%% Step all axes down (X/Y: 22.5 V, Z: 8 um)
fprintf('\n=== STEP DOWN (X/Y: 22.5 V, Z: 8 um) ===\n');
PX.SetOutputVoltage(vDown);
PY.SetOutputVoltage(vDown);
PZ.SetPosition(System.Decimal(8.0));
pause(0.8);
try PX.RequestOutputVoltage(); catch; end
try PY.RequestOutputVoltage(); catch; end
pause(0.3);
fprintf('X voltage readback: %.2f V\n', System.Decimal.ToDouble(PX.GetOutputVoltage()));
fprintf('Y voltage readback: %.2f V\n', System.Decimal.ToDouble(PY.GetOutputVoltage()));
SGx.RequestReading(); SGy.RequestReading(); PZ.RequestPosition(); pause(0.4);
xDown = sgToUM(SGx.GetReading());
yDown = sgToUM(SGy.GetReading());
zDown = System.Decimal.ToDouble(PZ.GetPosition());
fprintf('X = %.3f um\nY = %.3f um\nZ = %.3f um\n', xDown, yDown, zDown);

%% Return all axes to center
fprintf('\n=== RETURNING TO CENTER ===\n');
PX.SetOutputVoltage(vCenter);
PY.SetOutputVoltage(vCenter);
PZ.SetPosition(System.Decimal(10.0));
pause(1.5);
SGx.RequestReading(); SGy.RequestReading(); PZ.RequestPosition(); pause(0.4);
xFinal = sgToUM(SGx.GetReading());
yFinal = sgToUM(SGy.GetReading());
zFinal = System.Decimal.ToDouble(PZ.GetPosition());
fprintf('X = %.3f um\nY = %.3f um\nZ = %.3f um\n', xFinal, yFinal, zFinal);

%% Pass / fail
% X, Y: direction test (up > center > down) + repeatability within 2 um
% Z:    absolute position test within 0.5 um of 10 um
okX = (xUp > xCenter) && (xDown < xCenter) && (abs(xFinal - xCenter) < 2.0);
okY = (yUp > yCenter) && (yDown < yCenter) && (abs(yFinal - yCenter) < 2.0);
okZ = abs(zFinal - 10) < 0.5;

fprintf('\n=== RESULT ===\n');
if okX
    fprintf('X: PASS  (center=%.3f, up=%.3f, down=%.3f, final=%.3f um)\n', xCenter, xUp, xDown, xFinal);
else
    fprintf('X: FAIL  (center=%.3f, up=%.3f, down=%.3f, final=%.3f um)\n', xCenter, xUp, xDown, xFinal);
    if ~(xUp > xCenter);  fprintf('  -> did not move up (check TPZ001 cable to NanoMax X piezo)\n'); end
    if ~(xDown < xCenter); fprintf('  -> did not move down\n'); end
    if abs(xFinal - xCenter) >= 2.0; fprintf('  -> poor repeatability (%.3f um drift)\n', abs(xFinal-xCenter)); end
end
if okY
    fprintf('Y: PASS  (center=%.3f, up=%.3f, down=%.3f, final=%.3f um)\n', yCenter, yUp, yDown, yFinal);
else
    fprintf('Y: FAIL  (center=%.3f, up=%.3f, down=%.3f, final=%.3f um)\n', yCenter, yUp, yDown, yFinal);
    if ~(yUp > yCenter);  fprintf('  -> did not move up (check KPZ101 cable to NanoMax Y piezo)\n'); end
    if ~(yDown < yCenter); fprintf('  -> did not move down\n'); end
    if abs(yFinal - yCenter) >= 2.0; fprintf('  -> poor repeatability (%.3f um drift)\n', abs(yFinal-yCenter)); end
end
if okZ; fprintf('Z: PASS\n'); else; fprintf('Z: FAIL (%.3f um, expected ~10 um)\n', zFinal); end

if okX && okY && okZ
    fprintf('ALL AXES PASS.\n');
else
    fprintf('SOME AXES FAILED — check hardware connections and Kinesis setup.\n');
end

%% Clean up
PX.StopPolling();  PX.Disconnect();
SGx.StopPolling(); SGx.Disconnect();
PY.StopPolling();  PY.Disconnect();
SGy.StopPolling(); SGy.Disconnect();
PZ.StopPolling();  PZ.Disconnect();
fprintf('All connections closed.\n');
