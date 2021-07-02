classdef FilterWheel < handle
    %FILTERWHEEL
    % This class holds methods for communicating with and controlling the
    % FW102C Thorlabs motorized filter wheel. The functions written as of
    % 09/07/2012 are focused on using this for neutral density filters that
    % change the 532 nm laser power.
    
    % the only instance of this class is created upon start-up of the
    % ImageScan.m program. The GUI controls have been placed on the
    % ImageScan.fig front panel.
    
    properties
        openPortSuccess = 0; % 0 for unsuccessful, 1 for successful
        
        % hardcoded filter values, since we won't be changing often the
        % filters inside the motor wheel. This is primarily for ease of use
        % and does not affect the filter changing mechanics
        filterAssignment1 = [0 0.3 0.6 1.0 2.0 3.0];
        filterAssignment2 = [1 2 3 4 5 6];
        currentPos = 1; % 1,2,3,4,5,6
        FWCtrl;
        wheelID = 1; % 1 or 2 for excitation (1) and collection (2)
    end
    
    methods
        function obj = FilterWheel(handles, inputID)
            % we need to open communications with the FW102C wheel
            % I have chosen to do this with the ActiveX control that comes
            % with the FW102 software. This COM (component object model)
            % based and similar to communications with our Nanoscope
            % program (except that is over the network to AFMPC)
            
            % find the PROGID by first registering the ACtiveX control by
            % navigating in the command line 'cmd' (right-click, run as admin)
            % use the command: Regsvr32 FW102.ocx once in the directory
            % with that file. (program files/thorlabs/...etc
            % then, you can go to 'regedit' and scroll down to find that
            % the period-delimited progid, which is the argument used in
            % the actxcontrol matlab function:
            obj.FWCtrl = actxcontrol('FW102.FW102Ctrl.1');
            obj.wheelID = inputID;
            
            % opens a dialog box, choose the COM3, or whichever available.
            % This is sort of a virtual COM port, since it is a USB
            % connection instead of serial
            obj.FWCtrl.SelectCommPort;
            
            % opens the selected communication port, probably COM3
            obj.openPortSuccess = obj.FWCtrl.OpenPort;
            
            % figure out the current position and say it on indicator
            if obj.openPortSuccess==1
               obj.currentPos = obj.FWCtrl.Position;
               if (obj.wheelID == 1)
                   % filter 1 is for ND filters of excitation path
                   obj.changeODIndicator(handles);
               end
               if (obj.wheelID == 2)
                    % filter 2 is detection (PL versus green reflection)
                    obj.changeDetectionIndicator(handles);
               end
            else
                % if the device is not connected, the port open will not be
                % completed, so the filter wheel controls must be disabled
                % or do nothing.
            end
            %obj.changeODIndicator();
        end
        
        function goToFilter(obj, handles, newPos)
           % this is called by clicking an ImageScan GUI button 1,2,3,4,5,6
           % this does the required number of increments/decrements to change it from
           % the current position to newPos, an integer 1,2,3,4,5,6.
           % newPos argument assignment depends on the button callback
           
           if obj.openPortSuccess==1
               
               % double-check current position, in case it changed
               obj.currentPos = obj.FWCtrl.Position;
               %diffPos = newPos - obj.currentPos;

               % travel the shortest distance to adajcent filters
               % this is outlined on page 68 of my notebook3, but actually we
               % can just use their function to set Position and it
               % automatically goes the shortest distance
               obj.FWCtrl.set('Position',newPos);
               %tstart = tic;
               %while toc(tstart)<3
               %end
               % give it some time to change before setting displays
               if (obj.wheelID == 1)
                   % filter 1 is for ND filters of excitation path
                   obj.changeODIndicator(handles);
               end
               if (obj.wheelID == 2)
                    % filter 2 is detection (PL versus green reflection)
                    obj.changeDetectionIndicator(handles);
               end
           else
               msgbox('Communication with the filter wheel is not initialized. The device may be powered off or disconnected. Close ImageScan and connect the unit if it is needed.','FW102C Filter Wheel','error');
           end
           
        end
        
        function changeODIndicator(obj, handles)
           % this changes the actual Optical Density (OD) number displayed
           % on the ImageScan GUI, as well as the sum with the non-motor
           % wheel. 
           if obj.openPortSuccess==1
                obj.currentPos = obj.FWCtrl.Position;
           end
           tempOD = obj.filterAssignment1(obj.currentPos);
           set(handles.outputMotorNDFilter,'String',num2str(tempOD));
           set(handles.outputCombinedOD,'String',num2str(tempOD + str2double(get(handles.inputStationaryNDFilter,'String'))));
        end
        
        function changeDetectionIndicator(obj, handles)
            if obj.openPortSuccess==1
                obj.currentPos = obj.FWCtrl.Position;
            end
            if obj.currentPos == 1
                set(handles.indicatorDetectionFilter,'BackgroundColor',[0.85 0.16 0]);
            elseif obj.currentPos == 2
                set(handles.indicatorDetectionFilter,'BackgroundColor',[0 0.5 0]);
            else
                set(handles.indicatorDetectionFilter,'BackgroundColor',[0.941 0.941 0.941]);
            end
            set(handles.indicatorDetectionFilter,'String',num2str(obj.filterAssignment2(obj.currentPos)));
        end
    end
    
end

