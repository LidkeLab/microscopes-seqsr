% test_setup_stepper.m
% Exercise the new setupStageStepper logic in isolation:
% - connect to mic.StepperMotor
% - check homed bit, home if needed (no-op if already homed)
% - move all axes to safe position
% - verify positions
%
% Mirrors the logic in MIC_SEQ_SRcollect.setupStageStepper (without
% needing to construct the full SEQ object).
% Hardware: NO sample on stage required by caller.

SerialNo = '70850323';
HOMED_BIT = uint32(hex2dec('400'));

fprintf('Connecting to mic.StepperMotor(%s)...\n', SerialNo);
stepper = mic.StepperMotor(SerialNo);
pause(2);  % let LoadSettings/EnableChannel/StartPolling settle

%% Check homed status of all channels
fprintf('\n=== HOMED STATUS ===\n');
labels = {'Y', 'X', 'Z'};
for ch = 1:3
    status = uint32(stepper.getStatus(ch));
    isHomed = bitand(status, HOMED_BIT) > 0;
    pos = stepper.getPosition(ch);
    fprintf('Ch %d (%s): pos=%.4f mm  status=0x%08X  homed=%d\n', ...
        ch, labels{ch}, pos, status, isHomed);
end

%% Home any not-homed axis (Z first for safety)
HomeOrder = [3, 1, 2];
HomeLabels = {'Z', 'Y', 'X'};
for ii = 1:3
    ch = HomeOrder(ii);
    status = uint32(stepper.getStatus(ch));
    if bitand(status, HOMED_BIT) == 0
        fprintf('\nHoming %s (ch %d)...\n', HomeLabels{ii}, ch);
        stepper.goHome(ch);
        for t = 1:60
            pause(1);
            status = uint32(stepper.getStatus(ch));
            if bitand(status, HOMED_BIT) ~= 0
                fprintf('  homed at t=%ds\n', t);
                break
            end
        end
    else
        fprintf('\n%s (ch %d) already homed - skipping.\n', HomeLabels{ii}, ch);
    end
end

%% Move to safe position (matches setupStageStepper logic)
fprintf('\n=== MOVING TO SAFE POSITION ===\n');
fprintf('Z -> 4.0 mm\n');
stepper.moveToPosition(3, 4);
fprintf('Y -> 2.0650 mm\n');
stepper.moveToPosition(1, 2.0650);
fprintf('X -> 2.2780 mm\n');
stepper.moveToPosition(2, 2.2780);
pause(5);

%% Verify final positions
fprintf('\n=== FINAL POSITIONS ===\n');
X = stepper.getPosition(2);
Y = stepper.getPosition(1);
Z = stepper.getPosition(3);
fprintf('X = %.4f mm (target 2.2780)\n', X);
fprintf('Y = %.4f mm (target 2.0650)\n', Y);
fprintf('Z = %.4f mm (target 4.0000)\n', Z);

ok = abs(X - 2.2780) < 0.002 && abs(Y - 2.0650) < 0.002 && abs(Z - 4) < 0.002;
if ok
    fprintf('\nSUCCESS: stepper setup logic works end-to-end.\n');
else
    fprintf('\nFAIL: positions not reached.\n');
end

%% Now also test the recovery-mode stepper open: just connect, check
%% homed status, then moveToPosition(3, 4) without doing setupStageStepper.
fprintf('\n=== RECOVERY MODE TEST ===\n');
fprintf('Moving Z to 1.5 (simulated loaded position)...\n');
stepper.moveToPosition(3, 1.5);
pause(5);
fprintf('Z now at %.4f\n', stepper.getPosition(3));
fprintf('\nDeleting and reconnecting (simulates crash recovery)...\n');
stepper.delete();
pause(2);

stepper2 = mic.StepperMotor(SerialNo);
pause(2);
statusZ = uint32(stepper2.getStatus(3));
homedZ = bitand(statusZ, HOMED_BIT) > 0;
posZ = stepper2.getPosition(3);
fprintf('After reconnect: Z=%.4f mm, homed=%d, status=0x%08X\n', ...
    posZ, homedZ, statusZ);

if homedZ
    fprintf('Recovery: Z still homed across reconnect. Raising stage...\n');
    stepper2.moveToPosition(3, 4);
    pause(5);
    fprintf('Z now at %.4f mm\n', stepper2.getPosition(3));
    fprintf('RECOVERY MODE WORKS.\n');
else
    fprintf('Z lost homed state across reconnect - recovery would abort.\n');
end

stepper2.delete();
fprintf('\nDone.\n');
