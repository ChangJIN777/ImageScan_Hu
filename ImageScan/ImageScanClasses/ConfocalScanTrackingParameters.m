classdef ConfocalScanTrackingParameters < handle
    % current confocal tracking parameters - saved under handles.TrackingParameters
    % (confocal tracking size, dwell time, etc.)
    %
    % these parameters can be changed by the tracking parameters box from ImageScan
    % here is where the initial parameters are set
    
    properties
        MinValues;                  % x, y, z
        MaxValues;                  % x, y, z        
        NPoints =       [7 7 7];    % x, y, z
        DwellTime =     0.01;       % seconds (for 3d tracking scan)
        CompDwellTime = 3;          % seconds (for each point comparison after scan)
        PostDwellTime = 3;          % seconds (time between continuous tracks. 
                                    % This "post" running count continues after tracking history is updated
        OffsetValues =  [0 0 0];   % x, y, z in [microns]
        bEnable =       [1 1 1];    % Default to 3D scan
        bSaveData =     false;
        filename = '';
        TrackingThreshold = 1.01;
        
%         % ImageScan will access these current confocal parameters from this ConfocalScanParameters class made in ScanControl instance
%         % they are actually defined in the ConfigureImageScan class
%         micronsPerVoltX;
%         micronsPerVoltY;
%         micronsPerVoltZ;
%         voltsPerMicronX;    % inverse
%         voltsPerMicronY;    % inverse
%         voltsPerMicronZ;    % inverse
        
        TrackingBoxSize = 2; % size in microns
        TrackingBoxSizeZ = 3;  
    end
    
    methods
    
        function obj = ConfocalScanTrackingParameters(handles)
              obj.MaxValues(1:2) = obj.TrackingBoxSize/2;
              obj.MaxValues(3) = obj.TrackingBoxSizeZ/2;
              obj.MinValues = -obj.MaxValues;
              
%                % these are a copy of the calibration parameters from the ConfigureImageScan class:
%                obj.micronsPerVoltX = handles.configS.xScanMicronsPerVolt;
%                obj.micronsPerVoltY = handles.configS.xScanMicronsPerVolt;
%                obj.micronsPerVoltZ = handles.configS.zScanMicronsPerVolt;
%                obj.voltsPerMicronX = 1/obj.micronsPerVoltX;
%                obj.voltsPerMicronY = 1/obj.micronsPerVoltY;
%                obj.voltsPerMicronZ = 1/obj.micronsPerVoltZ;
        end
        
        function [obj] = ImportScan(obj,S)
            
            obj.MaxValues = S.MaxValues;
            obj.MinValues = S.MinValues;
            obj.NPoints = S.NPoints;
            obj.DwellTime = S.DwellTime;
            obj.OffsetValues = S.OffsetValues;
            obj.bEnable = S.bEnable;
            obj.bSaveData = S.bSaveData;
            obj.TrackingThreshold = S.TrackingThreshold;
            obj.TrackingBoxSize = S.TrackingBoxSize;
            obj.filename = S.filename;
        end
        
        function [S] = ExportScan(obj)
            
            S.MaxValues = obj.MaxValues;
            S.MinValues = obj.MinValues;
            S.NPoints = obj.NPoints;
            S.DwellTime = obj.DwellTime;
            S.OffsetValues = obj.OffsetValues;
            S.bEnable = obj.bEnable;
            S.bSaveData = obj.bSaveData;
            S.TrackingThreshold = obj.TrackingThreshold;
            S.TrackingBoxSize = obj.TrackingBoxSize;
            S.filename = obj.filename;
        end
        
        function bool = haveSameRegion(obj,S)
            bool = isequal(obj.MaxValues, S.MaxValues) ...
                && isequal(obj.MinValues, S.MinValues) ... 
                && isequal(obj.NPoints, S.NPoints) ...
                && isequal(obj.OffsetValues, S.OffsetValues) ... 
                && isequal(obj.bEnable, S.bEnable);
        end
    end

end