classdef ConfigureImageScan < handle
    % confocal calibration and max voltages - known as "configS"
    
    
    properties
        bAutoSave =     1;          % autosave images
        bHaveInverterBoard = 1;     % inverter board      
        bHaveNanoscopeAFM = 1;      % AFM
        numUSBFilterWheels = 2;     % 
        bHaveZurichInstr = 0;       % Zurich Instruments
        bHaveMCLXYZScanner = 0;     %
        bMagnetGui = 1;             %
        
        dataFolder  =    'C:\Users\lab\Documents\dataIm\2019_Apr_25\';
        % modified by Chang 7/11/21 (subject to change)
%         sequenceFolder = 'C:\Users\lab\Documents\MATLAB\ImageScan_v2019\PulseBlaster\PulseSequences\';
        sequenceFolder = 'C:\Users\lab\Documents\MATLAB\ImageScan_in_development\ImageScan_v2019_1219setup\PulseBlaster\PulseSequences\';
        
        % confocal piezo calibration
%         xScanMicronsPerVolt =   6;     % x [mu/V], old definition removed with v2019
%         yScanMicronsPerVolt =   6;     % y [mu/V]
%         zScanMicronsPerVolt =   12.5;  % z [mu/V]
        micronsPerVoltX =    143.66999999999999;      % x [mu/V];
        micronsPerVoltY =    136.97300000000001;      % y [mu/V];
        micronsPerVoltZ =   10;    % z [mu/V]; 
        voltsPerMicronX;
        voltsPerMicronY;
        voltsPerMicronZ;     
        
        % confocal piezo limits 
        % (FYI: best to choose X and Y voltages the same, as mNIDAQ_Driver
        % will set both limits to the smaller one in e.g. an xy scan)
        xMinVolts = -4.9002699999999999;      
        xMaxVolts =  4.9002699999999999;
        yMinVolts = -4.9002699999999999;
        yMaxVolts =  4.9002699999999999;
        zMinVolts =  0;
        zMaxVolts =  10;
        AnalogOutMinVoltages;
        AnalogOutMaxVoltages;
                      
        % photo diode calibration
        bPhotoDiode = false;
        photoDiodeConversion =  0;     % [uW/V]
        photoDiodeDark =        0;     % [V]
        
        % other parameters
        imageScanBGColorR = 231;
        imageScanBGColorG = 231;
        imageScanBGColorB = 231;
        xScanMicronsPerVolt = 25.508796;
        yScanMicronsPerVolt = 25.508796;
        zScanMicronsPerVolt = 10;
        
    end %properties
    
    methods 
        
          function obj = ConfigureImageScan()
            
            % these are a copy of the calibration parameters from the ConfigureImageScan class:
            obj.voltsPerMicronX = 1/obj.micronsPerVoltX;    % inverse
            obj.voltsPerMicronY = 1/obj.micronsPerVoltY;    % inverse
            obj.voltsPerMicronZ = 1/obj.micronsPerVoltZ;    % inverse
            
            % restructuring to allow easy dimension read out
            obj.AnalogOutMinVoltages = [obj.xMinVolts, obj.yMinVolts, obj.zMinVolts];
            obj.AnalogOutMaxVoltages = [obj.xMaxVolts, obj.yMaxVolts, obj.zMaxVolts];
            
        end
    end
    
end