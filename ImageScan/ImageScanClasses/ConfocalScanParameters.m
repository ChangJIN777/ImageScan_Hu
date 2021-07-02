classdef ConfocalScanParameters < handle
    % current confocal imaging parameters - saved under handles.ScanParameters
    % (confocal scan size, dwell time, etc.)
    
    properties
        MinValues =     [-50 -50 0];      % x, y, z  in µm, current scan setting
        MaxValues =     [50 50 100];         % x, y, z  in µm, current scan setting
        NPoints =       [80 80 200];        % x, y, z
        DwellTime =     0.004               % seconds
        OffsetValues =  [0 0 0];            % x, y, z % 0 for now, be sure to put these as microns also...
        bEnable =       [1 1 0];            % enabled axes for a default to 2D scan
        bSaveData =     false;
%         absoluteMaxValues;                  %saved in DAQ driver (05/19 SB)
%         absoluteMinValues;                  %saved in DAQ driver
        TrackingThreshold = 1.5;
        
%         % ImageScan will access these current confocal parameters from this ConfocalScanParameters class made in ScanControl instance
%         % they are actually defined in the ConfigureImageScan class
%         micronsPerVoltX;
%         micronsPerVoltY;
%         micronsPerVoltZ; 
%         voltsPerMicronX;     % inverse
%         voltsPerMicronY;     % inverse
%         voltsPerMicronZ;     % inverse
    end 
    
    
    
    methods
    
        function obj = ConfocalScanParameters(~)
            
%             % these are a copy of the calibration parameters from the ConfigureImageScan class:
%             obj.micronsPerVoltX = handles.configS.xScanMicronsPerVolt;
%             obj.micronsPerVoltY = handles.configS.yScanMicronsPerVolt;
%             obj.micronsPerVoltZ = handles.configS.zScanMicronsPerVolt;
%             obj.voltsPerMicronX = 1/obj.micronsPerVoltX;
%             obj.voltsPerMicronY = 1/obj.micronsPerVoltY;
%             obj.voltsPerMicronZ = 1/obj.micronsPerVoltZ;
            
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