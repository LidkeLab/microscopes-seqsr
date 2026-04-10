% test_recovery_move.m
% Test: can moveToPosition work after delete+reconnect (homed=0)?
% Simulates crash recovery scenario.

SerialNo = '70850323';
HOMED_BIT = uint32(hex2dec('400'));

%% First session: connect, home, move Z to 1.5 (simulated loaded position)
fprintf('=== SESSION 1: setup ===\n');
s1 = mic.StepperMotor(SerialNo);
pause(2);

% Home Z if needed
statusZ = uint32(s1.getStatus(3));
if bitand(statusZ, HOMED_BIT) == 0
    fprintf('Homing Z...\n');
    s1.goHome(3);
    for t = 1:60
        pause(1);
        if bitand(uint32(s1.getStatus(3)), HOMED_BIT) ~= 0
            fprintf('  homed at t=%ds\n', t);
            break
        end
    end
end

fprintf('Moving Z to 1.5 mm (simulated loaded position)...\n');
s1.moveToPosition(3, 1.5);
pause(5);
fprintf('Z = %.4f mm\n', s1.getPosition(3));

fprintf('Closing connection (simulates MATLAB crash)...\n');
s1.delete();
pause(2);

%% Second session: reconnect WITHOUT homing. Try moveToPosition.
fprintf('\n=== SESSION 2: recovery attempt ===\n');
s2 = mic.StepperMotor(SerialNo);
pause(2);

statusZ = uint32(s2.getStatus(3));
homedZ = bitand(statusZ, HOMED_BIT) > 0;
posZ = s2.getPosition(3);
fprintf('After reconnect: Z=%.4f mm, homed=%d, status=0x%08X\n', ...
    posZ, homedZ, statusZ);

fprintf('\nAttempting moveToPosition(3, 4) despite homed=%d...\n', homedZ);
s2.moveToPosition(3, 4);

for t = 1:15
    pause(1);
    posZ = s2.getPosition(3);
    fprintf('  t=%2ds  Z=%.4f mm\n', t, posZ);
    if abs(posZ - 4.0) < 0.01
        fprintf('  Z reached 4.0 mm - MOVE WORKS WITHOUT HOMED FLAG!\n');
        break
    end
end

finalZ = s2.getPosition(3);
fprintf('\nFinal Z = %.4f mm\n', finalZ);
if abs(finalZ - 4.0) < 0.01
    fprintf('SUCCESS: recovery moveToPosition works without homing.\n');
else
    fprintf('FAIL: Z did not reach target.\n');
end

s2.delete();
fprintf('Done.\n');
