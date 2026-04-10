% test_stepper_debug.m
% Home all axes with velocity tuning and long timeout for Z.
% IMPORTANT: Sample must NOT be on the stage.

SerialNo = '70850323';
HOMED_BIT = uint32(hex2dec('400'));

%% Connect
fprintf('=== OPENING CONNECTION ===\n');
Err = Kinesis_SBC_Open(SerialNo);
fprintf('SBC_Open returned: %d (0=success)\n', Err);
pause(3);

%% Read current homing velocities
fprintf('\n=== CURRENT HOMING VELOCITIES ===\n');
labels = {'Y', 'X', 'Z'};
for ch = 1:3
    vel = Kinesis_SBC_GetHomingVelocity(SerialNo, ch);
    fprintf('Ch %d (%s): homing velocity = %d (raw units)\n', ch, labels{ch}, vel);
end

%% Read move velocities for comparison
fprintf('\n=== CURRENT STATUS ===\n');
for ch = 1:3
    pos = Kinesis_SBC_GetPosition(SerialNo, ch);
    status = uint32(Kinesis_SBC_GetStatusBits(SerialNo, ch));
    isHomed = bitand(status, HOMED_BIT) > 0;
    fprintf('Ch %d (%s): pos=%.4f mm, status=0x%08X, homed=%d\n', ...
        ch, labels{ch}, pos, status, isHomed);
end

%% Set Z homing velocity to match X/Y if it's lower
velY = Kinesis_SBC_GetHomingVelocity(SerialNo, 1);
velZ = Kinesis_SBC_GetHomingVelocity(SerialNo, 3);
if velZ < velY
    fprintf('\nZ homing velocity (%d) is lower than Y (%d). Setting Z to match Y...\n', velZ, velY);
    err = Kinesis_SBC_SetHomingVelocity(SerialNo, 3, velY);
    fprintf('SetHomingVelocity returned: %d\n', err);
    velZ_new = Kinesis_SBC_GetHomingVelocity(SerialNo, 3);
    fprintf('Z homing velocity now: %d\n', velZ_new);
end

%% Home all channels
fprintf('\n=== HOMING ALL CHANNELS ===\n');
for ch = [3, 1, 2]
    ret = Kinesis_SBC_Home(SerialNo, ch);
    fprintf('Home(ch %d / %s) returned: %d\n', ch, labels{ch}, ret);
end

%% Monitor homing - 180s timeout for Z
fprintf('\n=== MONITORING HOMING (180s max) ===\n');
homedFlags = [false, false, false];
for t = 1:180
    pause(1);
    line = sprintf('t=%3ds ', t);
    allHomed = true;
    for ch = 1:3
        pos = Kinesis_SBC_GetPosition(SerialNo, ch);
        status = uint32(Kinesis_SBC_GetStatusBits(SerialNo, ch));
        isHomed = bitand(status, HOMED_BIT) > 0;
        isMoving = bitand(status, uint32(hex2dec('30'))) > 0;
        if isHomed && ~homedFlags(ch)
            homedFlags(ch) = true;
            fprintf('  >>> Ch %d (%s) HOMED at t=%ds <<<\n', ch, labels{ch}, t);
        end
        line = [line, sprintf('%s:%.4f/h%d/m%d  ', labels{ch}, pos, isHomed, isMoving)];
        if ~isHomed
            allHomed = false;
        end
    end
    % Print every 5s or when something changes, to reduce spam
    if mod(t, 5) == 0 || allHomed
        fprintf('%s\n', line);
    end
    if allHomed
        fprintf('All channels homed!\n');
        break
    end
end

if ~allHomed
    fprintf('WARNING: Not all channels homed within timeout.\n');
    fprintf('Closing...\n');
    Kinesis_SBC_Close(SerialNo);
    return
end

%% Move test: all channels
fprintf('\n=== MOVE TEST ===\n');
targets = [2.0, 2.0, 4.0];  % Y, X, Z
for ch = 1:3
    fprintf('Moving %s to %.1f mm...\n', labels{ch}, targets(ch));
    Kinesis_SBC_MoveToPosition(SerialNo, ch, targets(ch));
end
for t = 1:30
    pause(1);
    line = sprintf('t=%2ds ', t);
    allDone = true;
    for ch = 1:3
        pos = Kinesis_SBC_GetPosition(SerialNo, ch);
        line = [line, sprintf('%s:%.4f  ', labels{ch}, pos)];
        if abs(pos - targets(ch)) > 0.01
            allDone = false;
        end
    end
    fprintf('%s\n', line);
    if allDone
        fprintf('All channels reached targets!\n');
        break
    end
end

%% Return to 0
fprintf('\n=== RETURNING ALL TO 0 ===\n');
for ch = 1:3
    Kinesis_SBC_MoveToPosition(SerialNo, ch, 0.0);
end
for t = 1:30
    pause(1);
    line = sprintf('t=%2ds ', t);
    allDone = true;
    for ch = 1:3
        pos = Kinesis_SBC_GetPosition(SerialNo, ch);
        line = [line, sprintf('%s:%.4f  ', labels{ch}, pos)];
        if abs(pos) > 0.01
            allDone = false;
        end
    end
    fprintf('%s\n', line);
    if allDone
        fprintf('All channels at 0!\n');
        break
    end
end

%% Close
fprintf('\nClosing...\n');
Kinesis_SBC_Close(SerialNo);
fprintf('Done.\n');
