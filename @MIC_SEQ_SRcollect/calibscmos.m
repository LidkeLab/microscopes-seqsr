function calibscmos(obj)

obj.CameraSCMOS.ReturnType = 'matlab';

% Define a few parameters.
LampPowerRange = [0,linspace(1.6, 6, 14)]; % selected to reach ~600 max. camera counts
obj.CameraSCMOS.DefectCorrection = 1; % no correction
obj.CameraSCMOS.ScanMode = 1; % slow scan
obj.CameraSCMOS.ExpTime_Sequence = 0.01;
obj.CameraSCMOS.SequenceLength = 1000;
obj.CameraSCMOS.ROI = obj.SCMOS_ROI_Collect; % [XStart, XEnd, YStart, YEnd]

% Collect the gain/offset data.
Params = [];
MeanLevel = [];
VarLevel = [];
obj.CameraSCMOS.AcquisitionType = 'sequence';
obj.CameraSCMOS.setup_acquisition();
obj.Lamp660.on();
for ii = 1:numel(LampPowerRange)
    fprintf('Lamp power %i of %i\n', ii, numel(LampPowerRange))
    obj.Lamp660.setPower(LampPowerRange(ii));
    pause(1)
    obj.CameraSCMOS.start_sequence();
    MeanLevel = cat(3, MeanLevel, mean(obj.CameraSCMOS.Data, 3));
    VarLevel = cat(3, VarLevel, var(single(obj.CameraSCMOS.Data), [], 3));
end
obj.Lamp660.setPower(0);
Params.MeanLevel = single(MeanLevel);
Params.VarLevel = single(VarLevel);

% LSQ Fit
Beta = NaN(size(MeanLevel, 1), size(MeanLevel, 2), 2); % [:, :, 1] is ls offset, [:, :, 2] is ls slope
for ii = 1:size(MeanLevel, 1)
    for jj = 1:size(MeanLevel, 2)
        Beta(ii, jj, 1:2) = smi_stat.leastSquaresFit(...
            squeeze(MeanLevel(ii, jj, :)), squeeze(VarLevel(ii, jj, :)), ...
            1 ./ squeeze(VarLevel(ii, jj, :)));
    end
end

Params.CCDVar=single(VarLevel(:,:,1));
Params.Gain=single(Beta(:,:,2));
Params.CCDOffset=single(MeanLevel(:,:,1));

xdata = MeanLevel;
ydata = VarLevel;
yfit = xdata.*Beta(:,:,2)+Beta(:,:,1);
mse = (yfit-ydata).^2;

obj.CalibDataSCMOS = Params;
% save calibration results
[p,~]=fileparts(which('MIC_SEQ_SRcollect'));
FileName = fullfile(p,'GainCalibration.mat');
Params.CameraObj.ROI = obj.CameraSCMOS.ROI;
Params.LampPowerRange = single(LampPowerRange);
save(FileName, 'Params', '-v7.3')
end