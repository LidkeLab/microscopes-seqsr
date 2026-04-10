% test_stepper_homing.m
% Test stepper motor status and homing from MATLAB.
% Run with hardware powered on but Kinesis software CLOSED.
% IMPORTANT: Sample must NOT be on the stage - homing moves toward objective.
%
% Serial number for SEQ stepper controller: 70850323
% Channels: 1=Y, 2=X, 3=Z

SerialNo = '70850323';

%% Connect to stepper controller
fprintf('Opening connection to stepper controller %s...\n', SerialNo);
stepper = mic.StepperMotor(SerialNo);
fprintf('Connected.\n\n');

%% Check current positions and status before homing
fprintf('=== PRE-HOMING STATE ===\n');
channels = [1, 2, 3];
labels = {'Y', 'X', 'Z'};
for ii = 1:3
    ch = channels(ii);
    pos = stepper.getPosition(ch);
    status = stepper.getStatus(ch);
    fprintf('%s (ch %d): pos=%.4f mm, statusBits=0x%08X (%d)\n', ...
        labels{ii}, ch, pos, uint32(status), status);
end

%% Home each axis: Z first, then Y, then X
homeOrder = [3, 1, 2];
homeLabels = {'Z', 'Y', 'X'};

for ii = 1:3
    ch = homeOrder(ii);
    lbl = homeLabels{ii};

    fprintf('\nHoming %s axis (channel %d)...\n', lbl, ch);
    stepper.goHome(ch);

    % Wait for homing to complete
    maxWait = 60;  % seconds - homing can be slow
    for t = 1:maxWait
        pause(1);
        pos = stepper.getPosition(ch);
        status = stepper.getStatus(ch);
        fprintf('  t=%2ds  pos=%8.4f mm  status=0x%08X\n', t, pos, uint32(status));
        if abs(pos) < 0.001 && t > 3
            fprintf('  %s axis homed (pos=%.4f mm).\n', lbl, pos);
            break
        end
        if t == maxWait
            warning('%s axis did not reach home within %d seconds.', lbl, maxWait);
        end
    end
end

%% Check post-homing state
fprintf('\n=== POST-HOMING STATE ===\n');
for ii = 1:3
    ch = channels(ii);
    pos = stepper.getPosition(ch);
    status = stepper.getStatus(ch);
    fprintf('%s (ch %d): pos=%.4f mm, statusBits=0x%08X (%d)\n', ...
        labels{ii}, ch, pos, uint32(status), status);
end

%% Test: move Z to safe position and back to confirm positioning works
fprintf('\nMoving Z to 4.0 mm (safe position)...\n');
stepper.moveToPosition(3, 4);
pause(10);
zPos = stepper.getPosition(3);
fprintf('Z position after move: %.4f mm\n', zPos);

fprintf('Moving Z back to home...\n');
stepper.moveToPosition(3, 0);
pause(10);
zPos = stepper.getPosition(3);
fprintf('Z position after return: %.4f mm\n', zPos);

%% Cleanup
fprintf('\nClosing connection...\n');
stepper.delete();
fprintf('Done.\n');
