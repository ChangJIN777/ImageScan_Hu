classdef CursorControl < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DAQ; %handle to DAQ driver
        dwellTime = 0.05;%time in seconds 
        NSamples = 2;
        counterData;%array of counter samples for current scan
        counterValue;
        NSamplesAcquired;%how many counter samples have been acquired in the current scan
        dutyCycle = 0.5;
        voltageX;
        voltageY;
        voltageZ;
        hCursor = [];
        externalStop = true;
        countHistory = [];
        trackPosition = [0 0 0];
        trackData = [];
        continueTracking = false;
        hTrackingCursor = [];
        maxHistorySize = 1000;
        lastSample = 0;
        numCounts = 0;
        bDebug = true;
        oldVal;
        newVal;
        aiVoltages = [];
        bMeasureAI = false;
        hTrackFig1 = 4454321;
        hTrackFig2 = 4454322;
        hTrackFig3 = 4454323;
        trackingHistory = zeros(5000,3);
        trackingHistIndex = 1;
        bTestNewVsOld = true;
        bMCLTracking = false;
    end
    
    events(ListenAccess = 'public', NotifyAccess = 'protected')
        CountFinished;
    end
    
    methods
        function obj = CursorControl(DAQ)
            obj.DAQ = DAQ;
%             obj.ScanParameters.absoluteMinValues = DAQ.AnalogOutMinVoltages;
%             obj.ScanParameters.absoluteMaxValues = DAQ.AnalogOutMaxVoltages;
            %obj.hZoomBox = imrect(handles.axesCountHistory, [0 0 .1 .1]);
            %obj.hZoomBox.delete();
        end
        
        %function createZoomBox(obj, handles, tab)
        %    tabs = get(handles.tabGroup, 'Children');
        %    if ~exist('tab', 'var')
        %        tab = handles.ScanControl.currentTab;
        %    end
        %    currentAxes = get(tab, 'UserData');
        %    xbounds = get(currentAxes,'XLim');
        %    ybounds = get(currentAxes,'YLim');

        %    xlimits = [handles.DAQManager.DAQ.AnalogOutMinVoltages(DAQManager.X)...
        %        handles.DAQManager.DAQ.AnalogOutMaxVoltages(DAQManager.X)];
        %    index = find(get(handles.tabGroup, 'Children')==tab);
        %    xbounds = xbounds - handles.ScanControl.ScanParameters(index).OffsetValues(DAQManager.X);
            
        %    ylimits = [handles.DAQManager.DAQ.AnalogOutMinVoltages(DAQManager.Y)...
        %        handles.DAQManager.DAQ.AnalogOutMaxVoltages(DAQManager.Y)];
        %    ybounds = ybounds - handles.ScanControl.ScanParameters(index).OffsetValues(DAQManager.Y);

        %    xlimits = [handles.ScanControl.ScanParameters(index).MinValues(1),...
        %        handles.ScanControl.ScanParameters(index).MaxValues(1)];
        %    ylimits = [handles.ScanControl.ScanParameters(index).MinValues(2),...
        %        handles.ScanControl.ScanParameters(index).MaxValues(2)];
        %    xmin = min(xlimits);
        %    xdiff = abs(diff(xlimits));
        %    ymin = min(ylimits);
        %    ydiff = abs(diff(ylimits));
        %    if xmin < handles.DAQManager.DAQ.AnalogOutMinVoltages(1)
        %        xmin = handles.DAQManager.DAQ.AnalogOutMinVoltages(1);
        %    end
        %    if ymin < handles.DAQManager.DAQ.AnalogOutMinVoltages(2)
        %        ymin = handles.DAQManager.DAQ.AnalogOutMinVoltages(2);
        %    end
        %    if (xmin+xdiff)> handles.DAQManager.DAQ.AnalogOutMaxVoltages(1)
        %        xdiff = handles.DAQManager.DAQ.AnalogOutMaxVoltages(1)-xmin;
        %    end
        %    if (ymin+ydiff)> handles.DAQManager.DAQ.AnalogOutMaxVoltages(2)
        %        ydiff = handles.DAQManager.DAQ.AnalogOutMaxVoltages(2)-ymin;
        %    end
        %    obj.hZoomBox(index) = imrect(currentAxes,...
        %        [xmin ymin xdiff ydiff]);
        %    fcnBoxContraint = makeConstrainToRectFcn('imrect',...
        %        xbounds,ybounds);
        %    setPositionConstraintFcn(obj.hZoomBox(index),fcnBoxContraint);  
        %end
        
        %function deleteZoomBox(obj,handles, tab)
        %    if ~exist('tab', 'var')
        %        tab = handles.ScanControl.currentTab;
        %    end
        %    tabs = get(handles.tabGroup, 'Children')';
        %    index = find(tabs == tab);
        %    if ~isempty(obj.hZoomBox(index));
        %        obj.hZoomBox(index).delete();
        %    end
            %hold(currentAxes,'off');
        %end
        
        function createManualCursor(obj, handles)
            %currentAxes = get(handles.ScanControl.currentTab, 'UserData');
            currentAxes = handles.confocalAxes;
            %obj.updatePositionFromEdit(handles,handles.editPositionX,1,0.0);
            %obj.updatePositionFromEdit(handles,handles.editPositionY,2,0.0);
            %hold(currentAxes,'on');
            positionX = str2double(get(handles.editPositionX,'String'));
            positionY = str2double(get(handles.editPositionY,'String'));
            positionZ = str2double(get(handles.editPositionZ,'String'));
            [dimA,dimB] = obj.determineAxesDims(handles);
            switch dimA
                case DAQManager.X
                    positionA = positionX;
                case DAQManager.Y
                    positionA = positionY;
            end
            switch dimB
                case DAQManager.Y
                    positionB = positionY;
                case DAQManager.Z
                    positionB = positionZ;
            end
            
            % 9-17-12, 9-18-12. get microns/volts conversions. I want to
            % take the voltage limits but constrain to the microns
            % boundaries. "cmpv"="cursor microns per volt"
            cmpv = zeros(1,3);
            cmpv(1)=handles.ScanControl.ScanParameters(1).micronsPerVoltX;
            cmpv(2)=handles.ScanControl.ScanParameters(1).micronsPerVoltY;
            cmpv(3)=handles.ScanControl.ScanParameters(1).micronsPerVoltZ;
            
            % place a cursor from the ginput() function's coordinates 
            hold(currentAxes,'on');
            obj.hCursor = plot(currentAxes,positionX,positionY,'+g',...
                       'MarkerSize',15);
            hold(currentAxes,'off');
            
            % impoint code to comment out 4/19/2013 for new cursor
            %-----------------------------
%             obj.hCursor = impoint(currentAxes,positionA,positionB);
%             get(obj.hCursor)
% 
%             addNewPositionCallback(obj.hCursor,...
%                 @(position)obj.updatePositionFromCursor(handles,position));
%             boundsA = [handles.DAQManager.DAQ.AnalogOutMinVoltages(dimA)*cmpv(dimA)...
%                 handles.DAQManager.DAQ.AnalogOutMaxVoltages(dimA)*cmpv(dimA)];
% 
%             boundsA = boundsA - handles.ScanControl.ScanParameters(1).OffsetValues(dimA);
%             
%             boundsB = [handles.DAQManager.DAQ.AnalogOutMinVoltages(dimB)*cmpv(dimB)...
%                 handles.DAQManager.DAQ.AnalogOutMaxVoltages(dimB)*cmpv(dimB)];
%             boundsB = boundsB - handles.ScanControl.ScanParameters(1).OffsetValues(dimB);
%             fcnCursorContraint = makeConstrainToRectFcn('impoint',...
%                 boundsA,boundsB);
%             setPositionConstraintFcn(obj.hCursor,fcnCursorContraint);
%             setColor(obj.hCursor,'black'); 
%             setString(obj.hCursor,'MC');
            %-----------------------

        end
        
        function [dimA,dimB] = determineAxesDims(obj,handles)

                    strAxisA = get(get(handles.confocalAxes,'XLabel'),'String');
                    strAxisB = get(get(handles.confocalAxes,'YLabel'),'String');

                switch strAxisA
                    case 'X'
                        dimA = DAQManager.X;
                    case 'Y'
                        dimA = DAQManager.Y;
                    otherwise
                        dimA = DAQManager.X;
                end
                switch strAxisB
                    case 'Y'
                        dimB = DAQManager.Y;
                    case 'Z'
                        dimB = DAQManager.Z;
                    otherwise
                        dimB = DAQManager.Y;                
                end
        end
        
        function deleteManualCursor(obj,handles)
            currentAxes = handles.confocalAxes;
            if ~isempty(obj.hCursor);
                delete(obj.hCursor);
                obj.hCursor = [];
            end
            if ~isempty(currentAxes)
                hold(currentAxes,'off');
            end
        end
               
        
        function updatePositionFromCursor(obj,handles,position)
            [dimA,dimB] = obj.determineAxesDims(handles);

            valueA = position(1);
            obj.updateVoltage(handles,dimA,valueA);
            valueB = position(2);
            obj.updateVoltage(handles,dimB,valueB);
            
            strA = sprintf('%.2f',valueA);
            strB = sprintf('%.2f',valueB);
            switch dimA
                case DAQManager.X
                    hEditA = handles.editPositionX;
                case DAQManager.Y
                    hEditA = handles.editPositionY;
            end
            switch dimB
                case DAQManager.Y
                    hEditB = handles.editPositionY;
                case DAQManager.Z
                    hEditB = handles.editPositionZ;
            end
            set(hEditA,'String',strA);
            set(hEditB,'String',strB); 
        end
        

        function updatePositionFromEdit(obj,handles,hEdit,coordinate,increment)
            bScanningWithManualCoordinate = handles.StateControl.state == StateControl.SCANNING...
                        && handles.ScanControl.currentScanParameters.bEnable(coordinate) == false;
            if handles.StateControl.state == StateControl.IDLE ...
                    || handles.StateControl.state == StateControl.CURSOR ...
                    || bScanningWithManualCoordinate
                value = str2double(get(hEdit,'String'));
                value = obj.updateVoltage(handles,coordinate,value+increment);
                set(hEdit,'String',num2str(value));
            end
            bUpdateXorY = coordinate == 1 || coordinate == 2;
            bManualCursorState = handles.StateControl.state == StateControl.IDLE...
                    || handles.StateControl.state == StateControl.CURSOR;
            if bManualCursorState && bUpdateXorY
                obj.deleteManualCursor(handles);
                obj.createManualCursor(handles);
            end
        end
        
        function printValue = updateVoltage(obj,handles,coordinate,value)
            % 9-17-12, 9-18-12: the "coordinate" is still index, but the
            % "value" is passed in as a microns value. It will be here
            % converted to a voltage.
            cmpv = zeros(1,3);
            cmpv(1)=handles.ScanControl.ScanParameters(1).micronsPerVoltX;
            cmpv(2)=handles.ScanControl.ScanParameters(1).micronsPerVoltY;
            cmpv(3)=handles.ScanControl.ScanParameters(1).micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.ScanControl.ScanParameters(1).voltsPerMicronX;
            cvpm(2)=handles.ScanControl.ScanParameters(1).voltsPerMicronY;
            cvpm(3)=handles.ScanControl.ScanParameters(1).voltsPerMicronZ;
            
            %index = find(get(handles.tabGroup, 'Children')==handles.ScanControl.currentTab);
            value = value +...
                handles.ScanControl.ScanParameters(1).OffsetValues(coordinate);
            value = obj.coerce_range(value,...
                handles.DAQManager.DAQ.AnalogOutMaxVoltages(coordinate)*cmpv(coordinate),...
                handles.DAQManager.DAQ.AnalogOutMinVoltages(coordinate)*cmpv(coordinate));
            printValue = value - handles.ScanControl.ScanParameters(1).OffsetValues(coordinate);
            % at this point "value" is still in microns units
            % multiply by cvpm in this last step to write a voltage [volts]
            handles.DAQManager.DAQ.AnalogOutVoltages(coordinate) = value*cvpm(coordinate);
            handles.DAQManager.DAQ.WriteAnalogOutLine(coordinate);
            %c=[coordinate value]
        end
        
        function coerced = coerce_range(obj,value,high,low)
            if value > high
                coerced = high;
            elseif value < low
                coerced = low;
            else
                coerced = value;
            end
        end

        function runCount(obj,handles, bTrack, t)
            if ~exist('bTrack', 'var')
                bTrack = 0;
            end
            if ~exist('t', 'var')
                t = 0;
            end
            clocktime = tic;
            %handles         gui handles structure for ImageScan figure       
            obj.externalStop = false;
            obj.NSamplesAcquired = 0;

             obj.DAQ.ClearAllTasks();
            %Create a pulse train to act as a clock to coordinate the
            %counter measurements
            obj.DAQ.CreateTask('RunningPulseTrain');
            if bTrack == false %|| t > 10
                obj.updateDwellTime(handles);
            else
                obj.dwellTime = 0.1;%use short time for tracking
                % this is only a running count per-point dwell time and the
                % comparison dwell time is editable in ConfigureTracking...
            end
            
            clockFrequency = 1/obj.dwellTime;
            clockLine = 1;
            obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.dutyCycle);

            %set counter to save a sample at each position(voltage pair)
            %visited
            obj.DAQ.CreateTask('RunningCounter');
            counterLine = DAQManager.CTR1;
            obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.NSamples);
            %%correlated measurement of analog in 0
            % this is typically only for a photodiode, etc plugged in for
            % direct observation of laser power.
             obj.DAQ.CreateTask('RunningAI');
            if obj.bMeasureAI == true
               
                 aiLine = 1;
                 aiFig = figure;
                 aiAxes = axes;
                obj.DAQ.ConfigureVoltageIn('RunningAI',aiLine,obj.NSamples,clockLine);
            end
            
             
            while obj.externalStop == false
                obj.counterData = [];
                
                %obj.DAQ.ConfigureClockOut('RunningPulseTrain', 1,1/obj.dwellTime,obj.dutyCycle);
               
                if obj.bMeasureAI == true
                    obj.DAQ.StartTask('RunningAI');
                end
                % wait for tasks to start
                pause(0.01);%0.1 s in the Wittelbach program, change if problems arise.

                % start the sample clock
                obj.DAQ.StartTask('RunningPulseTrain');
                 obj.DAQ.StartTask('RunningCounter');
                while (obj.DAQ.IsTaskDone('RunningCounter') == false)
                    pause(obj.dwellTime);%seconds
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
                    if NSamplesAvailable > 0 
                        obj.counterData = [obj.counterData ...
                            obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)];
                    end
                end
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
                if NSamplesAvailable > 0 
                    obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)];
                end
                if obj.bMeasureAI == true
                    %%read analog in to correlate to counts
                    aiVoltage = obj.DAQ.ReadVoltageIn('RunningAI',obj.NSamples);
                    aiVoltage = aiVoltage(2);
%                     aiVoltage = obj.DAQ.ReadAnalogInLine(aiLine);
                    responsivity532 = 0.31;%A/W
                    transimpedance = 4.75e4;%%V/A
                    aiVoltage = aiVoltage / (transimpedance*responsivity532);
                    obj.aiVoltages = [obj.aiVoltages aiVoltage];
                    plot(aiAxes,obj.aiVoltages);
                    ylabel('Power (Watts)');
                end              
                obj.DAQ.StopTask('RunningAI');
                obj.DAQ.WaitUntilTaskDone('RunningCounter');
                obj.DAQ.StopTask('RunningCounter');
                obj.DAQ.StopTask('RunningPulseTrain');
                if length(obj.counterData) == 2
                    obj.counterValue=double(obj.counterData(2)-obj.counterData(1))/(1000.0*obj.dwellTime);
                    set(handles.editRunningCount,'String',num2str(obj.counterValue));

                    obj.addCountToHistory(handles,obj.counterValue);

                    obj.numCounts = obj.numCounts + 1;
                end
                
                drawnow();
                if bTrack && toc(clocktime) > t
                    obj.externalStop = true;
                end
            end
          
                
            obj.DAQ.ClearTask('RunningAI');
            obj.DAQ.ClearTask('RunningCounter');
            obj.DAQ.ClearTask('RunningPulseTrain');
            %obj.externalStop = true;
            %obj.notify('CountFinished');
        end
        
        function stopCount(obj)
           
            obj.externalStop = true;
           % obj.DAQ.WaitUntilTaskDone('RunningCounter');
           % obj.DAQ.ClearTask('RunningAI');
            %obj.DAQ.ClearTask('RunningCounter');
           % obj.DAQ.ClearTask('RunningPulseTrain'); 
  
        end

        function changeDwell(obj)
            obj.externalStop = true;
           
           
           
           % 
           %obj.DAQ.WaitUntilTaskDone('RunningCounter');
           % obj.DAQ.ClearTask('RunningAI');
           % obj.DAQ.ClearTask('RunningCounter');
           % obj.DAQ.ClearTask('RunningPulseTrain'); 
        end
        
        function addCountToHistory(obj,handles, countToAdd)
            if length(obj.countHistory) < obj.maxHistorySize
                obj.countHistory = [obj.countHistory countToAdd];
            else
                obj.countHistory = [obj.countHistory(2:end) countToAdd];
            end
            countsToShow = uint16(str2double(get(handles.editCountsToShow,'String')));
            if countsToShow == 0
                countsToShow = 100;
            end
            first = max(1,length(obj.countHistory)-countsToShow);
            last = min(first + countsToShow,length(obj.countHistory));
            x=first:last;
            obj.lastSample = countToAdd;
            plot(handles.axesCountHistory,x,obj.countHistory(x),'blue');
        end
        
        function resetCountHistory(obj)
            obj.countHistory = [];
            obj.aiVoltages = [];
            obj.numCounts = 0;
            % new 4-10, also reset tracking history
            obj.trackingHistory = zeros(5000,3);
            obj.trackingHistIndex = 1;
            
        end
        
        function updateDwellTime(obj,handles)
            obj.dwellTime = str2double(get(handles.editCountDwellTime,'String'));
            if isnan(obj.dwellTime) == true
                obj.dwellTime = 0.05;
            elseif obj.dwellTime < 0.05
                obj.dwellTime = 0.05;
            end
            set(handles.editCountDwellTime,'String',num2str(obj.dwellTime));
        end
        
        function startTrackingMode(obj,handles, bSingleTrack)
            %Starts tracking the weighted center of a user-defined region
            obj.DAQ.ClearAllTasks();
            obj.deleteManualCursor(handles);
            %if bSingleTrack == false
                obj.createTrackingCursor(handles);
            %end
            obj.runTracking(handles, bSingleTrack);
        end
        
        function endTrackingMode(obj,handles)
            %ends tracking immediately
            obj.deleteTrackingCursor(handles);
            obj.createManualCursor(handles)
            obj.continueTracking = false;
            set(handles.indicatorTrackingStatus,'String','Not tracking');
        end
        
        function runTracking(obj, handles, bSingleTrack)
            global Img_handles;
            %Performs a standard scan, and then uses the data to calculate
            %a center-of-mass of the data and follow it. May not work as
            %expected unless only a single bright spot is tracked.
            
            % 9-17-12, 9-18-12: this will be used several times below:
            cmpv = zeros(1,3);
            cmpv(1)=handles.ScanControl.ScanParameters(1).micronsPerVoltX;
            cmpv(2)=handles.ScanControl.ScanParameters(1).micronsPerVoltY;
            cmpv(3)=handles.ScanControl.ScanParameters(1).micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.ScanControl.ScanParameters(1).voltsPerMicronX;
            cvpm(2)=handles.ScanControl.ScanParameters(1).voltsPerMicronY;
            cvpm(3)=handles.ScanControl.ScanParameters(1).voltsPerMicronZ;
            
            if obj.bMCLTracking %If MCL tracking is on, do the tip-NV alignment first before laser tracking.
                global laser_x_handle;
                global laser_y_handle;
                global curr_center_x;
                global curr_center_y;
                global is_center;


                
                if is_center==1
                    'y'
                     mDAC('tip_tracking',curr_center_x,curr_center_y); 
                end
                                        
                laser_x = str2double(get(laser_x_handle,'String'));
                laser_y = str2double(get(laser_y_handle,'String'));
                mDAC('start_scan',laser_x,laser_y);
                
                %center = tip_tracking() %Gets data from current_scan.scan file in AFM file system directory
                
                pause(1);
                while mDAC('is_scan') == 1 %Wait for scan to end
                   pause(1);    
                end
                
                %Find center
                try
                     center = tip_tracking() %Gets data from current_scan.scan file in AFM file system directory
                catch
                    center = [curr_center_x curr_center_y 0];
                end
                offset = [0.0 0];%offset in volts
                if(center(3) <= 0.02) %track only if motion is less than 200 nm
                    curr_center_x = center(1);
                    curr_center_y = center(2);
                    is_center = 1;
                    mDAC('tip_tracking',center(1)-offset(1),center(2)-offset(2)); %Move tip center and reset scan center to be new center
                else
                    'Error: tracking outside range'
                end
                
                
            end
            
            
            if obj.bDebug == true
                try 
                    close(obj.hTrackFig1)
                catch 
                end
                pause(0.1)
                figXY = figure(obj.hTrackFig1);
                pause(0.1)
                clf(figXY);
                axesXY = axes;
                xlabel(axesXY,'X (V)');
                ylabel(axesXY,'Y (V)');
                title(axesXY,'Tracking XY View');
                try 
                    close(obj.hTrackFig2)
                catch 
                end
                pause(0.1)
                figXZ = figure(obj.hTrackFig2);
                clf(figXZ);
                axesXZ = axes;
                xlabel(axesXZ, 'X (V)');
                ylabel(axesXZ, 'Z (V)');
                title(axesXZ,'Tracking XZ View');
                
                try 
                    close(obj.hTrackFig3)
                catch 
                end
                pause(0.1)
                fig3Pos = figure(obj.hTrackFig3);
                clf(fig3Pos); % don't clear this history figure
                axes3Pos = axes;
                xlabel(axes3Pos, 'Tracking time step');
                ylabel(axes3Pos, 'Total Change');
                title(axes3Pos,'Tracking XYZ history');
                axis(axes3Pos,[0 obj.trackingHistIndex -0.01 0.01]);
                
            end
			fid = fopen('track_data.txt', 'a');
			fprintf(fid,'Starting Tracking\ndate\tx\ty\tz\told\tnew\tmoved\txmax\tymax\tzmax\tmax\n');
			fclose(fid);
            obj.continueTracking = true;
            while obj.continueTracking == true
                %bSingleTrack is set to true if tracking is meant to be
                %interweaved with other functions, like ESR measurements
                if bSingleTrack == true
                    obj.continueTracking = false;
                end
                %save the data cube under certain circumstances
                if obj.bDebug == true
                    if obj.oldVal < 50
                        handles.ScanControl.TrackingParameters(1).bSaveData = true;
                        handles.ScanControl.TrackingParameters(1).filename = 'track_cube_50.tiff';
                    elseif obj.oldVal < 100
                        handles.ScanControl.TrackingParameters(1).bSaveData = true;
                        handles.ScanControl.TrackingParameters(1).filename = 'track_cube_100.tiff';
                    elseif obj.oldVal < 200
                        handles.ScanControl.TrackingParameters(1).bSaveData = true;
                        handles.ScanControl.TrackingParameters(1).filename = 'track_cube_200.tiff';
                    else
                        handles.ScanControl.TrackingParameters(1).bSaveData = false;
                    end
                else
                    handles.ScanControl.TrackingParameters(1).bSaveData = false;
                end
                
                %Get the data from a scan
                set(handles.indicatorTrackingStatus,'String','3D scanning');
                scandata = handles.ScanControl.performScan(handles, true);
                if size(scandata, 1) == length(handles.ScanControl.XVoltages) ...
                        && size(scandata,2) == length(handles.ScanControl.YVoltages)...
                        && size(scandata, 3) == length(handles.ScanControl.ZVoltages)
                    n = 5;%Hardcoded weighting. The larger n is, the harder the tracking will adhere to the region of highest intensity
                    matsum = sum(sum(sum(double(scandata).^n)));%Discrete integral to find the total number of counts
                    %Calculate the X-, Y-, and Z-coordinates of the "center
                    %of mass"
                    % 9-17-12, 9-18-12 this center be calculated in units
                    % of [microns] and not [volts], use "cmpv(...)"
                    centerY = sum(sum((double(scandata).^n),3)*handles.ScanControl.YVoltages'*cmpv(2))/matsum;%Discrete integral for the Y-coordinate
                    centerX = sum(handles.ScanControl.XVoltages*cmpv(1)*(sum((double(scandata).^n),3)))/matsum;%Discrete integral for X
                    centerZ = sum(handles.ScanControl.ZVoltages*cmpv(3)*(sum((permute(double(scandata), [3 1 2]).^n),3)))/matsum;%Discrete Integral for Z
                    if isnan(centerZ)   %I've had some problems with getting NaN for centerZ, so this just keeps the z-location
                        %steady if that happens
                        centerZ = str2double(get(handles.editPositionZ, 'String'));
                    end
                    if isnan(centerX) || isnan(centerY)
                        %                         If centerX or centerY returns a NaN, then no data
                        %                         is being acquired, so just keep everything where
                        %                         it is
                        %  if isempty(obj.hTrackingCursor) == false
                        %      center = getPosition(obj.hTrackingCursor);
                        %   else
                        %       center = [0 0];
                        %   end

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %centerX = center(1); %
                        centerX = str2double(get(handles.editPositionX, 'String'));
                        centerY = str2double(get(handles.editPositionY, 'String'));
                        %centerY = center(2); %
                        
                        
                    end
                    
                    if obj.bDebug == true
                        p = [centerX centerY centerZ];
                        %useful for debugging, this plots the scan tracking
                        %sees next to the real scan
                        % 9-17-12, 9-18-12: again, these voltage values
                        % must convert into [microns]. centerX,Y,Z are
                        % already in microns due to changes above
                        mx = max(double(scandata(:)));
                        xbounds = [min(handles.ScanControl.XVoltages*cmpv(1)) max(handles.ScanControl.XVoltages*cmpv(1))];
                        xshift = (xbounds(2)-xbounds(1));
                        ybounds = [min(handles.ScanControl.YVoltages*cmpv(2)) max(handles.ScanControl.YVoltages*cmpv(2))];
                        yshift = (ybounds(2)-ybounds(1));
                        zbounds = [min(handles.ScanControl.ZVoltages*cmpv(3)) max(handles.ScanControl.ZVoltages*cmpv(3))];
                        zshift = (zbounds(2)-zbounds(1));
                        [xval xi] = min(abs(handles.ScanControl.XVoltages*cmpv(1)-centerX));
                        [yval yi] = min(abs(handles.ScanControl.YVoltages*cmpv(2)-centerY));
                        [zval zi] = min(abs(handles.ScanControl.ZVoltages*cmpv(3)-centerZ));

                        oldVal = obj.oldVal;
                        newVal = obj.newVal;
%                         %show the xy slice at the proposed z sligthly to
%                         %the right of where it is in the scan
%                         imagesc(xbounds+xshift,ybounds,transpose(scandata(:,:,zi),'Parent'));
%                         plot(centerX+xshift,centerY,'w+','MarkerSize',10);
%                         imagesc(xbounds,[ybounds(2) ybounds(2)+zshift],permute(scandata(:,yi,:),[1,3,2]));
%                         plot(centerX,centerZ-zbounds(1)+ybounds(2),'w+','MarkerSize',10);

                        cla(axesXY);
                        plot(axesXY,1);
                        imagesc(xbounds,ybounds,transpose(scandata(:,:,zi)),'Parent',axesXY);
                        
                        xlabel(axesXY,'X (µm)');
                        ylabel(axesXY,'Y (µm)');
                        title(axesXY,'Tracking XY View');
                        hold(axesXY,'on');
                        plot(axesXY,centerX,centerY,'y+','MarkerSize',20);
                        colorbar('peer',axesXY);
                        hold(axesXY,'off');
                        
                        cla(axesXZ);
                        plot(axesXZ,1);
                        imagesc(xbounds,zbounds,permute(scandata(:,yi,:),[3,1,2]),'Parent',axesXZ);
                        xlabel(axesXZ, 'X (µm)');
                        ylabel(axesXZ, 'Z (µm)');
                        title(axesXZ,'Tracking XZ View');
                        hold(axesXZ,'on');
                        plot(axesXZ,centerX,centerZ,'y+','MarkerSize',20);
                        colorbar('peer',axesXZ);
                        hold(axesXZ,'off');
                    end

                    %bChangePosition = ~obj.bTestNewVsOld || bSingleTrack || obj.changePositionByTracking(handles, centerX, centerY, centerZ) == true;
                    set(handles.indicatorTrackingStatus,'String','Comparing new/old');
                    bChangePosition = ~obj.bTestNewVsOld || obj.changePositionByTracking(handles, centerX, centerY, centerZ) == true;
                    if bChangePosition && obj.bMCLTracking
                       %update Z
                        set(handles.editPositionZ, 'String', num2str(centerZ));
                        obj.updateVoltage(handles, 3, centerZ);
                    end
                    
                    if bChangePosition% && ~obj.bMCLTracking
                        %Run if the new position is significantly better
                        %than the old one
                        %Set the edit box values
                        set(handles.editPositionX, 'String', num2str(centerX));
                       set(handles.editPositionY, 'String', num2str(centerY));
                        set(handles.editPositionZ, 'String', num2str(centerZ));
                        
                        %Move the tracking cursor to the new location
                        % 5/3/2013, changed this from deleting the cursor
                        % to simply changing the XY data properties.
                        obj.deleteTrackingCursor(handles);
                        obj.createTrackingCursor(handles);
                       % obj.hTrackingCursor.XData = str2double(get(handles.editPositionX,'String'));
                        %obj.hTrackingCursor.YData = str2double(get(handles.editPositionY,'String'));
                        
                        % 9-17-12, 9-18-12: again, updateVoltage takes in
                        % the position in microns and will convert
                        obj.updateVoltage(handles, 1, centerX);
                        obj.updateVoltage(handles, 2, centerY);
                        obj.updateVoltage(handles, 3, centerZ);
                        
           
                       
                        %Write the new location down in a text file
                        %fid = fopen('track_data.txt', 'a');
                        %fprintf(fid,  [datestr(now), '\t', num2str(centerX), '\t', num2str(centerY), '\t', num2str(centerZ), '\t', num2str(obj.lastSample),'\n']);
                        %fclose(fid);
                        
%                         %Perform a scan so that the image is refreshed
%                         handles.ScanControl.currentScanParameters.MaxValues(3) = centerZ;
%                         handles.ScanControl.currentScanParameters.MinValues(3) = centerZ;
%                         handles.ScanControl.currentScanParameters.NPoints(3) = 1;
%                         boxmin = handles.ScanControl.currentScanParameters.MinValues(1:2);
%                         boxmax = handles.ScanControl.currentScanParameters.MaxValues(1:2);
%                         if ~inpolygon(centerX, centerY, [boxmin(1) boxmax(1) boxmax(1) boxmin(1) boxmin(1)],...
%                                 [boxmin(2) boxmin(2) boxmax(2) boxmax(2) boxmin(2)])
%                             dif = handles.ScanControl.currentScanParameters.MaxValues(1:2)-...
%                                 handles.ScanControl.currentScanParameters.MinValues(1:2);
%                             if all(([centerX centerY] + dif/2) < handles.DAQManager.DAQ.AnalogOutMaxVoltages(1:2))&&...
%                                     all(([centerX centerY] - dif/2) > handles.DAQManager.DAQ.AnalogOutMinVoltages(1:2))
%                                 handles.ScanControl.currentScanParameters.MinValues(1:2) = [centerX centerY] - dif/2;
%                                 handles.ScanControl.currentScanParameters.MaxValues(1:2) = [centerX centerY] + dif/2;
%                             end
%                         end
%                         %update the picture
%                         handles.ScanControl.performScan(handles, false);
%                         
%                         %reset the cursor to the calculated center after
%                         %the scan is done
%                         set(handles.editPositionX, 'String', num2str(centerX));
%                         set(handles.editPositionY, 'String', num2str(centerY));
%                         set(handles.editPositionZ, 'String', num2str(centerZ));
%                         obj.deleteTrackingCursor(handles)
%                         obj.createTrackingCursor(handles)
%                         obj.updateVoltage(handles, 1, centerX);
%                         obj.updateVoltage(handles, 2, centerY);
%                         obj.updateVoltage(handles, 3, centerZ);
                    end
                    if obj.bDebug == true
                        if obj.trackingHistIndex == 100
                            obj.trackingHistory = circshift(obj.trackingHistory,-1);
                        end
 
                         obj.trackingHistory(obj.trackingHistIndex,1) = str2num(get(handles.editPositionX, 'String'));
                        obj.trackingHistory(obj.trackingHistIndex,2) = str2num(get(handles.editPositionY, 'String'));
                         obj.trackingHistory(obj.trackingHistIndex,3) = str2num(get(handles.editPositionZ, 'String')); 
            
                        % obj.trackingHistory(obj.trackingHistIndex,1) = centerX;
                        % obj.trackingHistory(obj.trackingHistIndex,2) = centerY;
                       %  obj.trackingHistory(obj.trackingHistIndex,3) = centerZ;
                        
                       laserX = str2num(get(handles.editPositionX, 'String'));
                       laserY = str2num(get(handles.editPositionY, 'String'));
                       laserZ = str2num(get(handles.editPositionZ, 'String'));
                      
 
                        cla(axes3Pos);
                        plot(axes3Pos,1);
                        xlabel(axes3Pos, 'Tracking time step');
                       % ylabel(axes3Pos, 'Differential Change (µm)');
                        ylabel(axes3Pos, 'Total Change (µm)');
                       title(axes3Pos,'Tracking XYZ history');
                       % axis(axes3Pos,[0 obj.trackingHistIndex -0.25 0.25]);
                        
                        hold(axes3Pos,'on');
                        %hold on;
                        
                       % trackingDiffX = diff(obj.trackingHistory(1:obj.trackingHistIndex,1));
                       % trackingDiffY = diff(obj.trackingHistory(1:obj.trackingHistIndex,2));
                       % trackingDiffZ = diff(obj.trackingHistory(1:obj.trackingHistIndex,3));
                       
                        trackingDiffX = obj.trackingHistory(1:obj.trackingHistIndex,1) - obj.trackingHistory(1,1);
                        trackingDiffY = obj.trackingHistory(1:obj.trackingHistIndex,2) - obj.trackingHistory(1,2);
                        trackingDiffZ = obj.trackingHistory(1:obj.trackingHistIndex,3) - obj.trackingHistory(1,3);
                        
                          %Compensate MCL stage to try to keep laser spot
                        %fixed (3/17/14)
                        if obj.bMCLTracking
                            % mDAC('adjust_tip_position',-(laserX - centerX), laserY-centerY);
                           %  -(laserX - centerX)
                            % laserY-centerY
                        end
                        
                     %  obj.trackingHistory(obj.trackingHistIndex,1)-obj.trackingHistory(obj.trackingHistIndex-1,1)
                      % obj.trackingHistory(obj.trackingHistIndex,2)-obj.trackingHistory(obj.trackingHistIndex-1,2)
                        
                        
                        
                       
                        length(trackingDiffX);
                        length(1:(obj.trackingHistIndex-1));
%                         plot(axes3Pos,(1:obj.trackingHistIndex),obj.trackingHistory(1:obj.trackingHistIndex,1),'r-');
%                         plot(axes3Pos,(1:obj.trackingHistIndex),obj.trackingHistory(1:obj.trackingHistIndex,2),'b-');
%                         plot(axes3Pos,(1:obj.trackingHistIndex),obj.trackingHistory(1:obj.trackingHistIndex,3),'k-');
                        if obj.trackingHistIndex >1
                            plot(axes3Pos,(1:(obj.trackingHistIndex)),trackingDiffX,'r-');
                            plot(axes3Pos,(1:(obj.trackingHistIndex)),trackingDiffY,'b-');
                            plot(axes3Pos,(1:(obj.trackingHistIndex)),trackingDiffZ,'k-');     
                        end
                        hold(axes3Pos,'off');
                        if obj.trackingHistIndex < 100
                            obj.trackingHistIndex = obj.trackingHistIndex+1;
                        end
                    end
                    
                    fid = fopen('track_data.txt', 'a');
                    fprintf(fid,  [datestr(now), '\t', num2str(centerX), '\t', num2str(centerY), '\t', num2str(centerZ),...
                        '\t', num2str(obj.oldVal), '\t', num2str(obj.newVal), '\t', num2str(bChangePosition)]);
                    if obj.bDebug == true
                        [overalMax,indMax]=max(double(scandata(:)));
                        [iMax jMax kMax] = ind2sub(size(scandata),indMax);
                        % 9-17-12, 9-18-12 Once again, in saving just give
                        % the microns instead of voltages.
                        xMax = handles.ScanControl.XVoltages(iMax)*cmpv(1);
                        yMax = handles.ScanControl.YVoltages(jMax)*cmpv(2);
                        zMax = handles.ScanControl.ZVoltages(kMax)*cmpv(3);
                        
                        fprintf(fid, ['\t' num2str(xMax) '\t' num2str(yMax)...
                            '\t' num2str(zMax) '\t' num2str(overalMax)]);
                    end
                    fprintf(fid, '\n');
                    fclose(fid);
                end
                if obj.continueTracking == true
                    set(handles.indicatorTrackingStatus,'String','Okay to stop');
                    obj.numCounts = 0;
                    obj.runCount(handles, true, handles.ScanControl.TrackingParameters.PostDwellTime);
                    %obj.runCount(handles,true, str2double(get(handles.editTrackingDwellTime, 'String')));
                end
            end
        end
        

        function createTrackingCursor(obj, handles)
            %Exactly the same as the Manual Cursor, but says "Tracking
            %Cursor" instead
%             tabs = get(handles.tabGroup, 'Children');
%             if handles.ScanControl.currentTab == tabs(end)
%                 handles.ScanControl.fixTabs(handles);
%             end
            currentAxes = handles.confocalAxes;
            x = str2double(get(handles.editPositionX,'String'));
            y = str2double(get(handles.editPositionY,'String'));
            
            hold(currentAxes,'on');
            obj.hTrackingCursor = plot(currentAxes,x,y,'sg',...
                       'MarkerSize',15);
            hold(currentAxes,'off');

            
            % ---old code 4/19/2013 commented for impoint cursor
%             obj.hTrackingCursor = impoint(currentAxes,x,y);
%             fcnCursorContraint = makeConstrainToRectFcn('impoint',...
%                 x*[1 1],y*[1 1]);
%             setPositionConstraintFcn(obj.hTrackingCursor,fcnCursorContraint);
%             setColor(obj.hTrackingCursor,'black'); 
%             setString(obj.hTrackingCursor,'TC');
        end
        
        function deleteTrackingCursor(obj,handles)
            %Deletes the trackin cursor
%             tabs = get(handles.tabGroup, 'Children');
%             if handles.ScanControl.currentTab == tabs(end)
%                 handles.ScanControl.fixTabs(handles);
%             end
            currentAxes = handles.confocalAxes;
            if ~isempty(obj.hTrackingCursor);
                % somehow I needed this "check=" line to avoid handle error
                try
                    delete(obj.hTrackingCursor);
                    obj.hTrackingCursor = [];
                catch delException
                    obj.hTrackingCursor = []; % occasional errors due to delete function
                end
            end
            hold(currentAxes,'off');
        end
        
        function bool = changePositionByTracking(obj, handles, centerX, centerY, centerZ)
            %Perform a quick scan at the new position and one at the old
            %position. If the ammount of light collected at the new
            %position is greater then the ammount at the old position by a
            %factor dictated by the "Tracking Threshold" property, then
            %return true
            
            % 9-17-12, 9-18-12: Analog out voltages are being written so
            % the conversions are needed.
            cmpv = zeros(1,3);
            cmpv(1)=handles.ScanControl.ScanParameters(1).micronsPerVoltX;
            cmpv(2)=handles.ScanControl.ScanParameters(1).micronsPerVoltY;
            cmpv(3)=handles.ScanControl.ScanParameters(1).micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.ScanControl.ScanParameters(1).voltsPerMicronX;
            cvpm(2)=handles.ScanControl.ScanParameters(1).voltsPerMicronY;
            cvpm(3)=handles.ScanControl.ScanParameters(1).voltsPerMicronZ;
            
           % if obj.continueTracking == true 
                % "currentScanParameters" is itself an instance of class
                % confocalScanParameters
                handles.DAQManager.DAQ.AnalogOutVoltages = cvpm.*handles.ScanControl.currentScanParameters.OffsetValues;
                
                % first set the cursor back to the old position and do a
                % running count
                % no need to call "AnalogOutVoltages()=..." since the old
                % position is already there..?
                oldX = handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.X);
                oldY = handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Y);
                oldZ = handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Z);
                handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.X);
                handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Y);
                handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Z);
                % pausing prevents a "tracking dip" likely due to the galvo 
                % voltages not being updated at the start of the running
                % count
                pause(0.5); 
                obj.numCounts = 0;
                % set in tracking parameters the comparison time
                t = handles.ScanControl.TrackingParameters.CompDwellTime; 
                obj.runCount(handles, true, t);
               % if obj.continueTracking == true 
                    if obj.numCounts >= 1
                        obj.oldVal = mean(obj.countHistory((end-obj.numCounts+1):end));
                    else
                        return
                    end
                    % change to the new position, center of mass, and then
                    % start a second running count
                    handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.X) = centerX*cvpm(1);
                    handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.X);
                    handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Y) = centerY*cvpm(2);
                    handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Y);
                    handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Z) = centerZ*cvpm(3);
                    handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Z);
                    % pausing prevents a "tracking dip" likely due to the galvo 
                    % voltages not being updated at the start of the running
                    % count
                    pause(0.5);
                    obj.numCounts = 0;
                    obj.runCount(handles, true, t);
                    if obj.numCounts >= 1
                        obj.newVal = mean(obj.countHistory((end-obj.numCounts+1):end));
                    else
                        return
                    end
                    if obj.newVal > handles.ScanControl.currentScanParameters.TrackingThreshold*obj.oldVal
                        bool = true;
                    else
                        bool = false;
                    end
                    
                    %if using MCL compensation, switch back to old x-y center
                    if obj.bMCLTracking
                     %    handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.X) = oldX;
                     %   handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.X);
                     %   handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Y) = oldY;
                     %   handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Y);
                      %  handles.DAQManager.DAQ.AnalogOutVoltages(DAQManager.Z) = oldZ;
                     %   handles.DAQManager.DAQ.WriteAnalogOutLine(DAQManager.Z);
                    end
                    
                    
                %else
               %     bool = false;
               % end
            %else
             %   bool = false;
            %end
        end
        function saveCountHistory(obj,handles)
           
            defaultPath = [pwd '\data\'];
            [filename fpath ~] = uiputfile('count_history.txt','Save As...',defaultPath);
            fid = fopen([fpath filename],'a');
            fprintf(fid,['\n' datestr(now) '\n']);
            for i=1:length(obj.countHistory)
                fprintf(fid,  [num2str(obj.countHistory(i)) '\n']);
            end
            fclose(fid);
        end
    end
    
end

