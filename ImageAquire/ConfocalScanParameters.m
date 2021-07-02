classdef ConfocalScanParameters < handle
    
    
    properties
%           MinValues = [-5 -5 40]; % x, y, z in volts, current scan setting
%           MaxValues = [5 5 60]; % x, y, z   in volts, current scan setting
        MinValues = [-125 -125 40]; % x, y, z in µm, current scan setting
        MaxValues = [125 125 60]; % x, y, z   in µm, current scan setting
        NPoints = [80 80 7]; % x, y, z
        DwellTime = 0.004 % seconds
        OffsetValues = [0 0 0]; % x, y, z % 0 for now, be sure to put these as microns also...
        bEnable = [1 1 0]; %Default to 2D scan
        bSaveData = false;
        absoluteMaxValues;%saved in DAQ driver
        absoluteMinValues;%saved in DAQ driver
        TrackingThreshold = 1.5;
        
        % ImageScan will access these values off this
        % ConfocalScanParameters class made in ScanControl
        % instance, microns-volts conversion
        micronsPerVoltX = 143.67;%25; % hardcoded for 60x oil objective and galvo.
         micronsPerVoltY = 136.973;%25; % hardcoded for 60x oil objective and galvo.
        micronsPerVoltZ = 10; % hardcoded for the MCL objective piezo
        voltsPerMicronX = 0.006960395;%0.04; % inverse
        voltsPerMicronY = 0.00730070;%0.04; % inverse
        voltsPerMicronZ = 0.1; % inverse
    end %properties
    
    methods
    
        % boring constructor
        function obj = ConfocalScanParameters(configStruct)
            
            % 04/19/2013 added input arguments for using a Image Scan
            % configuration file to set these things easily
            obj.micronsPerVoltX = configStruct.xScanMicronsPerVolt;
            obj.micronsPerVoltY = configStruct.yScanMicronsPerVolt;
            obj.micronsPerVoltZ = configStruct.zScanMicronsPerVolt;
            obj.voltsPerMicronX = 1/obj.micronsPerVoltX;
            obj.voltsPerMicronY = 1/obj.micronsPerVoltY;
            obj.voltsPerMicronZ = 1/obj.micronsPerVoltZ;
            
        end
        
        function [obj] = ImportScan(obj,S)
            
            % function [obj] = ImportScan(obj,S)
            % 
            % copies a structure object to current scan
            
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
            
            % function [S] = ExportScan(obj)
            %
            % returns a structure for the current scan
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