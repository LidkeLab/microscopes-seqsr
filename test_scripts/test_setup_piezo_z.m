% test_setup_piezo_z.m
% Standalone test for a single TPZ001 + TSG001 K-cube pair on the Z axis.
% - Connect to the piezo controller and strain gauge
% - Read the current position
% - Move to center (10 um), then step up and down
% - Return to center and clean up
%
% Hardware: Thorlabs TPZ001 (controller) + TSG001 (strain gauge)
% Connect the Z piezo channel of the NanoMax 300 to these K-cubes.

ControllerSerial = '81843229'; % TPZ001
GaugeSerial      = '84842506'; % TSG001

fprintf('Connecting to Z piezo...\n');
fprintf('  Controller: %s\n', ControllerSerial);
fprintf('  Gauge:      %s\n', GaugeSerial);

% Connect using the same MIC class used in setupStagePiezo.
% NanoMaxPiezos expects (Xctrl, Xgauge, Yctrl, Ygauge, Zctrl, Zgauge).
% For a single-axis test we pass the Z serials for all three axes so the
% class can construct without errors, but we only exercise the Z channel.
piezo = mic.stage3D.NanoMaxPiezos( ...
    ControllerSerial, GaugeSerial, ...
    ControllerSerial, GaugeSerial, ...
    ControllerSerial, GaugeSerial);
pause(2); % let the connection settle

%% Read initial position
pos = piezo.Position; % [X, Y, Z] in microns
fprintf('\n=== INITIAL POSITION ===\n');
fprintf('X=%.3f  Y=%.3f  Z=%.3f  (um)\n', pos(1), pos(2), pos(3));

%% Move Z to center (10 um is midrange for a 0-20 um piezo)
fprintf('\n=== MOVING TO CENTER (10 um) ===\n');
piezo.setPosition([pos(1), pos(2), 10]);
pause(0.5);
pos = piezo.Position;
fprintf('Position after center: Z=%.3f um\n', pos(3));

%% Step Z up by 2 um
fprintf('\n=== STEP UP +2 um ===\n');
piezo.setPosition([pos(1), pos(2), pos(3) + 2]);
pause(0.5);
pos = piezo.Position;
fprintf('Position after step up: Z=%.3f um\n', pos(3));

%% Step Z down by 4 um (net -2 from center)
fprintf('\n=== STEP DOWN -4 um ===\n');
piezo.setPosition([pos(1), pos(2), pos(3) - 4]);
pause(0.5);
pos = piezo.Position;
fprintf('Position after step down: Z=%.3f um\n', pos(3));

%% Return to center
fprintf('\n=== RETURNING TO CENTER ===\n');
piezo.setPosition([pos(1), pos(2), 10]);
pause(0.5);
pos = piezo.Position;
fprintf('Final position: Z=%.3f um\n', pos(3));

ok = abs(pos(3) - 10) < 0.5;
if ok
    fprintf('\nSUCCESS: Z piezo responds correctly.\n');
else
    fprintf('\nFAIL: Z piezo did not reach target (got %.3f um, expected ~10 um).\n', pos(3));
end

%% Clean up
piezo.delete();
fprintf('Connection closed.\n');
