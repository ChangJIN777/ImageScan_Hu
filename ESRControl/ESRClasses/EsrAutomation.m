classdef EsrAutomation < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
%        ESRControlFig;
       imageScanHandles;
       gesr;
       
    end
    
    methods
        function obj = EsrAutomation(handles)
           
           % handle to the AFM GUI called in ImageScan 
           % this is useless though since that GUI is not opened yet = []
%             obj.ESRControlFig = handles.ESRControl;
            obj.imageScanHandles = handles;
                      
            
       end
        
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
    end
    
end

