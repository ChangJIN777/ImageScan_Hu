classdef ConfocalScanTrackingParameters < handle
    
    
    properties
        MinValues; % x, y, z
        MaxValues; % x, y, z        
        NPoints = [7 7 7]; % x, y, z
        DwellTime = 0.01; % seconds (for 3d tracking scan)
        CompDwellTime = 2; % seconds (for each point comparison after scan)
        PostDwellTime = 3; % seconds (time between continuous tracks. 
                            %This "post" running count continues after tracking history is updated
        OffsetValues = [0 0 50]; % x, y, z in [microns]
        bEnable = [1 1 1]; %Default to 2D scan
        bSaveData = false;
        filename = '';
        TrackingThreshold = 1.01;
        
        % added microns/volts on 9-17-12, 9-18-12
        micronsPerVoltX = 143.67;%25; % hardcoded for 60x oil objective and galvo.
         micronsPerVoltY = 136.973;%25; % hardcoded for 60x oil objective and galvo.
        micronsPerVoltZ = 10; % hardcoded for the MCL objective piezo
        voltsPerMicronX = 0.006960395;%0.04; % inverse
        voltsPerMicronY = 0.00730070;%0.04; % inverse
        voltsPerMicronZ = 0.1; % inverse
        
        TrackingBoxSize = 0.8; % size in microns
        TrackingBoxSizeZ = 1.2;  
    end %properties
    
    methods
    
        function obj = ConfocalScanTrackingParameters(configStruct)
            ratioZtoX = 2.5;%1 V in Z is 10 um, 1 V in X/Y is 25 um
%             obj.MinValues = -obj.TrackingBoxSize/2 * [1 DAQManager.ratioYtoX (DAQManager.ratioZtoX)];
%             obj.MaxValues = obj.TrackingBoxSize/2 * [1 DAQManager.ratioYtoX (DAQManager.ratioZtoX)];
              obj.MaxValues(1:2) = obj.TrackingBoxSize/2 * [1 DAQManager.ratioYtoX];
              obj.MaxValues(3) = obj.TrackingBoxSizeZ/2;
              obj.MinValues = -obj.MaxValues;
              
              % 04/19/2013 added input arguments for using a Image Scan
                % configuration file to set these things easily
               obj.micronsPerVoltX = configStruct.xScanMicronsPerVolt;
               obj.micronsPerVoltY = configStruct.xScanMicronsPerVolt;
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
            obj.TrackingBoxSize = S.TrackingBoxSize;
            obj.filename = S.filename;
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