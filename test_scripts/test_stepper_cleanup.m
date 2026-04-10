% test_stepper_cleanup.m
% Minimal test to diagnose the DLL crash on exit.
% Try different cleanup strategies.

SerialNo = '70850323';

%% Connect
fprintf('Opening...\n');
Kinesis_SBC_Open(SerialNo);
pause(2);

%% Quick position read to confirm connection
pos = Kinesis_SBC_GetPosition(SerialNo, 1);
fprintf('Y pos: %.4f mm\n', pos);

%% Close with extra cleanup
fprintf('Stopping polling...\n');
% SBC_Close already calls StopPolling, but let's be explicit
Kinesis_SBC_Close(SerialNo);
fprintf('Connection closed.\n');

%% Wait for DLL to finish internal cleanup
pause(2);

%% Unload the mex files to release the DLLs before process exit
fprintf('Clearing mex files...\n');
clear mex;
pause(1);

fprintf('Exiting cleanly.\n');
