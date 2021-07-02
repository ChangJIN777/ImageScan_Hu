classdef backgroundDAQSession < handle
    
    properties
        inputSession
        rate
        dataLength
        photoDiodeInputChannel
        transportInputChannel
        lh
        gui_handles
    end
    
    methods
        function obj = backgroundDAQSession(rate, dataLength, gui_handles)
            obj.rate = rate;
            obj.dataLength = dataLength;
            obj.gui_handles = gui_handles;
        end
        
        function obj = initContSession(obj, gui_handles)
            obj.gui_handles = gui_handles;
            obj.inputSession = daq.createSession('ni');
            obj.inputSession.Rate = obj.rate;
            obj.inputSession.IsContinuous = true;
            
            obj.transportInputChannel = addAnalogInputChannel(obj.inputSession,'PXI1Slot2',0,'Voltage');
            obj.transportInputChannel.Range = [-0.5 0.5];
            obj.transportInputChannel.TerminalConfig = 'Differential';
            
            obj.lh = addlistener(obj.inputSession,'DataAvailable', @(hObject, event) obj.updateDAQBackgroundValues(hObject, event, obj.gui_handles));
            obj.inputSession.NotifyWhenDataAvailableExceeds = obj.dataLength;
            obj.inputSession.startBackground();
        end
        
        function obj = initGateSession(obj, rate, nSamples)
            obj.inputSession = daq.createSession('ni');
            obj.inputSession.Rate = rate;
            obj.inputSession.NumberOfScans = nSamples;
            
            obj.transportInputChannel = addAnalogInputChannel(obj.inputSession,'PXI1Slot2',0,'Voltage');
            obj.transportInputChannel.Range = [-0.5 0.5];
            obj.transportInputChannel.TerminalConfig = 'Differential';
        end
        
        function [meanV, stdV] = getDeviceVoltage(obj)
            deviceVData = startForeground(obj.inputSession);
            meanV = mean(deviceVData);
            stdV = std(deviceVData);
        end
        
        function updateDAQBackgroundValues(obj, ~, event, handles)
            % update photoDiode values
%             photoDiodeV = mean(event.Data(:,1));
%             photoDiodeVStr = sprintf('%.2f', photoDiodeV);
%             set(handles.photoDiodeVString, 'String', photoDiodeVStr);
%             greenPower = (photoDiodeV-handles.configS.photoDiodeDark)*handles.configS.photoDiodeConversion;
%             greenPowerStr = sprintf('%.1f', greenPower);
%             set(handles.greenPowerString, 'String', greenPowerStr);
            
            if(~isempty(findobj('Tag', 'TransportGUI')))
                % update transport plot
                set(handles.TransportGUIHandles.axes1,'NextPlot','replacechildren')
                plot(handles.TransportGUIHandles.axes1, handles.measureTime, event.Data(:,1)*1e3) % [mV]
                
                % update transport values
                niDiffV_mean = mean(event.Data(:,1));
                handles.TransportGUIHandles.niSourceI.String = sprintf('%.3f', (1e6)*((1e-3)*str2double(handles.TransportGUIHandles.niSourceV.String)-niDiffV_mean)/...
                    (str2double(handles.TransportGUIHandles.niSourceR.String)*(1e3)));
                if str2double(handles.TransportGUIHandles.niSourceFreq.String) == 0
                    niDeviceR = niDiffV_mean(1)*1e3/str2double(handles.TransportGUIHandles.niSourceI.String);  % [uV]/[uA] = [kOhm]
                else
                    niDeviceR = niDiffV_mean(1)*1e3/str2double(handles.TransportGUIHandles.niSourceI.String);  % [uVrms]*sqrt(2)/[uA] = [kOhm]
                end
                handles.TransportGUIHandles.niDeviceRMeasurement.deviceR = niDeviceR;
                handles.TransportGUIHandles.niDiffV.String = sprintf('%.3f', niDiffV_mean*1e3);
                handles.TransportGUIHandles.niDeviceR.String = sprintf('%.3f', niDeviceR);
            end
        end
        
        function obj = stopSession(obj)
            pause(0.1);
            stop(obj.inputSession);
            release(obj.inputSession);
        end
    end
    
end