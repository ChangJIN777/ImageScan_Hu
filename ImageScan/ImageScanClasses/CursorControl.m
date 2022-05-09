classdef CursorControl < handle
    % CursorControl performs all tasks with a steady laser postion
    %   it communicates with DAQ if the laser postion is changed, gathering 
    %   the running count data from the DAQ counters, runs NV tracking and
    %   updates the laser position accordingly
    
    properties
%         DAQ; %handle to DAQ driver
        dwellTime = 0.05;   %time in seconds 
        NSamples = 2;
        counterData;        %array of counter samples for current scan
        counterValue;
        NSamplesAcquired;   %how many counter samples have been acquired in the current scan
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
%         bMeasureAI = false; % replaced by "bPhotoDiode" in ConfigureImageScan class
        hTrackFig1 = 1001;      % tracking figure number 1
        hTrackFig2 = 1002;      % tracking figure number 2
        hTrackFig3 = 1003;      % tracking figure number 3
        trackingHistory = zeros(5000,3);
        trackingHistIndex = 1;
        bTestNewVsOld = true;
%         bMCLTracking = false;
        hPhotoDiode = 1004;     % photodiode figure
    end
    
    events(ListenAccess = 'public', NotifyAccess = 'protected')
        CountFinished;
    end
    
    methods
        function obj = CursorControl(~)
%             obj.DAQ = DAQ;
        end
        
        
        %---- draw laser cursor position after manual "laser cursor" button press or increment change in ImageScan -----     
        function createManualCursor(obj, handles)
            currentAxes = handles.confocalAxes;
            
            positionX = str2double(get(handles.editPositionX,'String'));
            positionY = str2double(get(handles.editPositionY,'String'));
            positionZ = str2double(get(handles.editPositionZ,'String'));
            [dimA,dimB] = obj.determineAxesDims(handles);
            switch dimA
                case handles.DAQManager.X
                    positionA = positionX;
                case handles.DAQManager.Y
                    positionA = positionY;
            end
            switch dimB
                case handles.DAQManager.Y
                    positionB = positionY;
                case handles.DAQManager.Z
                    positionB = positionZ;
            end
            
            % 9-17-12, 9-18-12. get microns/volts conversions. I want to
            % take the voltage limits but constrain to the microns
            % boundaries. "cmpv"="cursor microns per volt"
            cmpv = zeros(1,3);
            cmpv(1)=handles.configS.micronsPerVoltX;
            cmpv(2)=handles.configS.micronsPerVoltY;
            cmpv(3)=handles.configS.micronsPerVoltZ;
            
            % place a cursor from the ginput() function's coordinates
            hold(currentAxes,'on');
            obj.hCursor = plot(currentAxes,positionA,positionB,'+g',...
                'MarkerSize',15);
            hold(currentAxes,'off');
                       
        end
        
        %---- determine the new laser position according to axis labels -----------------------------------
        function [dimA,dimB] = determineAxesDims(~,handles)

            strAxisA = get(get(handles.confocalAxes,'XLabel'),'String');
            strAxisB = get(get(handles.confocalAxes,'YLabel'),'String');
            
            if isempty(strAxisA)
                strAxisA = 'X';
            end
            if isempty(strAxisB)
                strAxisB = 'Y';
            end
            
            switch strAxisA(1)
                case 'X'
                    dimA = handles.DAQManager.X;
                case 'Y'
                    dimA = handles.DAQManager.Y;
                otherwise
                    dimA = handles.DAQManager.X;
            end
            switch strAxisB(1)
                case 'Y'
                    dimB = handles.DAQManager.Y;
                case 'Z'
                    dimB = handles.DAQManager.Z;
                otherwise
                    dimB = handles.DAQManager.Y;
            end
        end
        
        %---- delete laser cursor whenever laser position is changed (laser cursor is redrawn at the end) ---------
        function deleteManualCursor(obj,handles)
            currentAxes = handles.confocalAxes;
            if ~isempty(obj.hCursor)
                delete(obj.hCursor);
                obj.hCursor = [];
            end
            if ~isempty(currentAxes)
                hold(currentAxes,'off');
            end
        end
               
        %---- change confocal positioning increment boxes according to new laser position --------------------------
        function updatePositionFromCursor(obj,handles,position)
            [dimA,dimB] = obj.determineAxesDims(handles);

            valueA = position(1);
            obj.updateVoltage(handles,dimA,valueA);
            valueB = position(2);
            obj.updateVoltage(handles,dimB,valueB);
            
            strA = sprintf('%.2f',valueA);
            strB = sprintf('%.2f',valueB);
            switch dimA
                case handles.DAQManager.X
                    hEditA = handles.editPositionX;
                case handles.DAQManager.Y
                    hEditA = handles.editPositionY;
            end
            switch dimB
                case handles.DAQManager.Y
                    hEditB = handles.editPositionY;
                case handles.DAQManager.Z
                    hEditB = handles.editPositionZ;
            end
            set(hEditA,'String',strA);
            set(hEditB,'String',strB); 
        end
        
        %---- update DAQ output, change image cursor etc. after laser position has been changed in edit box or increment buttons
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
        
        %---- change DAQ output after laser position has been changed -------------------------------------
        function printValue = updateVoltage(obj,handles,coordinate,value)
            % 9-17-12, 9-18-12: the "coordinate" is still index, but the
            % "value" is passed in as a microns value. It will be here
            % converted to a voltage.
            cmpv = zeros(1,3);
            cmpv(1)=handles.configS.micronsPerVoltX;
            cmpv(2)=handles.configS.micronsPerVoltY;
            cmpv(3)=handles.configS.micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.configS.voltsPerMicronX;
            cvpm(2)=handles.configS.voltsPerMicronY;
            cvpm(3)=handles.configS.voltsPerMicronZ;
            
            value = value +...
                handles.ScanParameters.OffsetValues(coordinate);
            value = obj.coerce_range(value,...
                handles.configS.AnalogOutMaxVoltages(coordinate)*cmpv(coordinate),...
                handles.configS.AnalogOutMinVoltages(coordinate)*cmpv(coordinate));
            printValue = value - handles.ScanParameters.OffsetValues(coordinate);
            % at this point "value" is still in microns units
            % multiply by cvpm in this last step to write a voltage [volts]
            handles.DAQManager.DAQ.AnalogOutVoltages(coordinate) = value*cvpm(coordinate);
            handles.DAQManager.DAQ.WriteAnalogOutLine(coordinate);

        end
        
        %---- check that required DAQ voltage is in range -------------------------------------------------
        function coerced = coerce_range(~,value,high,low)
            if value > high
                coerced = high;
            elseif value < low
                coerced = low;
            else
                coerced = value;
            end
        end

        %---- aquire counter data from DAQ ----------------------------------------------------------------
        function runCount(obj,handles, bTrack, t)
            if ~exist('bTrack', 'var')
                bTrack = 0;
            end
            if ~exist('t', 'var')
                t = 0;
            end
            clocktime = tic;
            obj.externalStop = false;
            obj.NSamplesAcquired = 0;

            handles.DAQManager.DAQ.ClearAllTasks();
            %Create a pulse train to act as a clock to coordinate the counter measurements
            handles.DAQManager.DAQ.CreateTask('RunningPulseTrain');
            if bTrack == false %|| t > 10
                obj.updateDwellTime(handles);
            else
                obj.dwellTime = 0.1;%use short time for tracking
                % this is only a running count per-point dwell time and the
                % comparison dwell time is editable in ConfigureTracking...
            end
            
            clockFrequency = 1/obj.dwellTime;
            clockLine = 1;
            handles.DAQManager.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine, clockFrequency,obj.dutyCycle);
            
            %set counter to save a sample at each position(voltage pair) visited
            counterLine = 1;
            handles.DAQManager.DAQ.CreateTask('RunningCounter');
            handles.DAQManager.DAQ.ConfigureCounterIn('RunningCounter', counterLine, obj.NSamples);
            %%correlated measurement of analog in 0
            % this is typically only for a photodiode, etc plugged in for
            % direct observation of laser power.
            if handles.configS.bPhotoDiode == true %obj.bMeasureAI == true
                handles.DAQManager.DAQ.CreateTask('RunningAI');
                handles.photoDiodeP = [];
%                 aiLine = 1;
%                 aiFig = figure;
%                 aiAxes = axes;
%                 handles.DAQManager.DAQ.ConfigureVoltageIn('RunningAI', aiLine, obj.NSamples, clockLine);
                aiFig = figure(obj.hPhotoDiode);
                set(aiFig,'Position',[670,50,575,200]);           
                clf(aiFig);
                aiAxes = axes;
            end
            
             
            while obj.externalStop == false
                obj.counterData = [];
                
%                 if handles.configS.bPhotoDiode == true %obj.bMeasureAI == true
%                     handles.DAQManager.DAQ.StartTask('RunningAI');
%                 end
                % wait for tasks to start
                pause(0.01); %0.1 s in the Wittelbach program, change if problems arise.
                
                % start the sample clock
                handles.DAQManager.DAQ.StartTask('RunningPulseTrain');
                handles.DAQManager.DAQ.StartTask('RunningCounter');
                while (handles.DAQManager.DAQ.IsTaskDone('RunningCounter') == false)
                    pause(obj.dwellTime); %seconds
                    NSamplesAvailable = handles.DAQManager.DAQ.GetAvailableSamples('RunningCounter');
                    if NSamplesAvailable > 0
                        obj.counterData = [obj.counterData ...
                            handles.DAQManager.DAQ.ReadCounterBuffer('RunningCounter', NSamplesAvailable)];
                    end
                end
                NSamplesAvailable = handles.DAQManager.DAQ.GetAvailableSamples('RunningCounter');
                if NSamplesAvailable > 0
                    obj.counterData = [obj.counterData handles.DAQManager.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)];
                end
                if handles.configS.bPhotoDiode == true %obj.bMeasureAI == true
                    %%read analog in to correlate to counts
                      % since this section has a calibration in here,
                      % hidden deep in the code - this is rewritten (04/2019 SB)
%                     aiVoltage = handles.DAQManager.DAQ.ReadVoltageIn('RunningAI',obj.NSamples);
%                     aiVoltage = aiVoltage(2);
%                     responsivity532 = 0.31;%A/W
%                     transimpedance = 4.75e4;%%V/A
%                     aiVoltage = aiVoltage / (transimpedance*responsivity532);
%                     obj.aiVoltages = [obj.aiVoltages aiVoltage];
                    photoDiodeV = handles.DAQManager.DAQ.ReadAnalogInVoltage(handles.DAQManager.photoDiodeAI);
                    photoDiodeVStr = sprintf('%.2f', photoDiodeV);
                    set(handles.photoDiodeVString, 'String', photoDiodeVStr);
                    greenPower = (photoDiodeV-handles.configS.photoDiodeDark)*handles.configS.photoDiodeConversion;
                    greenPowerStr = sprintf('%.1f', greenPower);
                    set(handles.greenPowerString, 'String', greenPowerStr);
                    handles.photoDiodeP = [handles.photoDiodeP greenPower];
                    plot(aiAxes,handles.photoDiodeP);
                    ylabel('Power (Watts)');
                end              
                handles.DAQManager.DAQ.StopTask('RunningAI');
                handles.DAQManager.DAQ.WaitUntilTaskDone('RunningCounter');
                handles.DAQManager.DAQ.StopTask('RunningCounter');
                handles.DAQManager.DAQ.StopTask('RunningPulseTrain');
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
          
                
            handles.DAQManager.DAQ.ClearTask('RunningAI');
            handles.DAQManager.DAQ.ClearTask('RunningCounter');
            handles.DAQManager.DAQ.ClearTask('RunningPulseTrain');

        end
        
        %---- change of state when tracking or running count is stopped -----------------------------------
        function stopCount(obj)
            obj.externalStop = true;
        end
        
        %---- change of dwell time while running count is still running -----------------------------------
        function changeDwell(obj)
            obj.externalStop = true;
        end
        
        %---- add count history to plot -------------------------------------------------------------------
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
            set(handles.axesCountHistory,'FontSize',9);
            set(handles.axesCountHistory.YLabel,'String','[kcounts/s]');

        end
        
        %---- reset count and tracking history upon button press in ImageScan -----------------------------
        function resetCountHistory(obj)
            obj.countHistory = [];
            obj.aiVoltages = [];
            obj.numCounts = 0;
            % new 4-10, also reset tracking history
            obj.trackingHistory = zeros(5000,3);
            obj.trackingHistIndex = 1;
            
        end
        
        %---- update running count dwell time -------------------------------------------------------------
        function updateDwellTime(obj,handles)
            obj.dwellTime = str2double(get(handles.editCountDwellTime,'String'));
            if isnan(obj.dwellTime) == true
                obj.dwellTime = 0.05;
            elseif obj.dwellTime < 0.05
                obj.dwellTime = 0.05;
            end
            set(handles.editCountDwellTime,'String',num2str(obj.dwellTime));
        end
        
        %---- initialize confocal tracking ----------------------------------------------------------------
        function startTrackingMode(obj,handles, bSingleTrack)
            %Starts tracking the weighted center of a user-defined region
            handles.DAQManager.DAQ.ClearAllTasks();
            obj.deleteManualCursor(handles);
            obj.createTrackingCursor(handles);
            obj.runTracking(handles, bSingleTrack);
        end
        
        %---- end confocal tracking -----------------------------------------------------------------------
        function endTrackingMode(obj,handles)
            %ends tracking immediately
            obj.deleteTrackingCursor(handles);
            obj.createManualCursor(handles)
            obj.continueTracking = false;
            set(handles.indicatorTrackingStatus,'String','Not tracking');
        end
        
        %---- run confocal tracking -----------------------------------------------------------------------
        function runTracking(obj, handles, bSingleTrack)
            %Performs a standard scan, and then uses the data to calculate
            %a center-of-mass of the data and follow it. May not work as
            %expected unless only a single bright spot is tracked.
            
            % 9-17-12, 9-18-12: this will be used several times below:
            cmpv = zeros(1,3);
            cmpv(1)=handles.configS.micronsPerVoltX;
            cmpv(2)=handles.configS.micronsPerVoltY;
            cmpv(3)=handles.configS.micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.configS.voltsPerMicronX;
            cvpm(2)=handles.configS.voltsPerMicronY;
            cvpm(3)=handles.configS.voltsPerMicronZ;
            
%             if obj.bMCLTracking %If MCL tracking is on, do the tip-NV alignment first before laser tracking.
%                 global laser_x_handle;
%                 global laser_y_handle;
%                 global curr_center_x;
%                 global curr_center_y;
%                 global is_center;
%                 
%                 if is_center==1
%                     'y'
%                      mDAC('tip_tracking',curr_center_x,curr_center_y); 
%                 end
%                                         
%                 laser_x = str2double(get(laser_x_handle,'String'));
%                 laser_y = str2double(get(laser_y_handle,'String'));
%                 mDAC('start_scan',laser_x,laser_y);
%                 
%                 %center = tip_tracking() %Gets data from current_scan.scan file in AFM file system directory
%                 
%                 pause(1);
%                 while mDAC('is_scan') == 1 %Wait for scan to end
%                    pause(1);    
%                 end
%                 
%                 %Find center
%                 try
%                      center = tip_tracking(); %Gets data from current_scan.scan file in AFM file system directory
%                 catch
%                     center = [curr_center_x curr_center_y 0];
%                 end
%                 offset = [0.0 0];%offset in volts
%                 if(center(3) <= 0.02) %track only if motion is less than 200 nm
%                     curr_center_x = center(1);
%                     curr_center_y = center(2);
%                     is_center = 1;
%                     mDAC('tip_tracking',center(1)-offset(1),center(2)-offset(2)); %Move tip center and reset scan center to be new center
%                 else
%                     dips('Error: tracking outside range');
%                 end
%                 
%                 
%             end
            
            
            if obj.bDebug == true % the figures are mainly used for debugging
                figXY = figure(obj.hTrackFig1); % tracking figure number 1 
                set(figXY,'Position',[20,50,300,200]); % positioning the tracking figure within the display 
                clf(figXY); 
                axesXY = axes; 
                xlabel(axesXY,'X (V)');
                ylabel(axesXY,'Y (V)');
                title(axesXY,'Tracking XY View');
                figXZ = figure(obj.hTrackFig2); % tracking figure number 2 
                clf(figXZ);
                set(figXZ,'Position',[350,50,300,200]); % positioning the tracking figure within the display 
                axesXZ = axes;
                xlabel(axesXZ, 'X (V)');
                ylabel(axesXZ, 'Z (V)');
                title(axesXZ,'Tracking XZ View');

                
            end
            % save the tracking data 
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
                        handles.TrackingParameters.bSaveData = true;
                        handles.TrackingParameters.filename = 'track_cube_50.tiff';
                    elseif obj.oldVal < 100
                        handles.TrackingParameters.bSaveData = true;
                        handles.TrackingParameters.filename = 'track_cube_100.tiff';
                    elseif obj.oldVal < 200
                        handles.TrackingParameters.bSaveData = true;
                        handles.TrackingParameters.filename = 'track_cube_200.tiff';
                    else
                        handles.TrackingParameters.bSaveData = false;
                    end
                else
                    handles.TrackingParameters.bSaveData = false;
                end
                
                %Get the data from a scan
                set(handles.indicatorTrackingStatus,'String','3D scanning');
                set(handles.buttonStartTracking,'String','tracking');
                scandata = handles.ScanControl.performScan(handles, true); % set bTracking to true to interrupt tracking
                if size(scandata, 1) == length(handles.ScanControl.XVoltages) ...
                        && size(scandata,2) == length(handles.ScanControl.YVoltages)...
                        && size(scandata, 3) == length(handles.ScanControl.ZVoltages)
                    n = 10;     %Hardcoded weighting. The larger n is, the harder the tracking will adhere to the region of highest intensity
                    matsum = sum(sum(sum(double(scandata).^n))); %Discrete integral to find the total number of counts
                    %Calculate the X-, Y-, and Z-coordinates of the "center of mass"
                    % 9-17-12, 9-18-12 this center be calculated in units
                    % of [microns] and not [volts], use "cmpv(...)"
                    centerY = sum(sum((double(scandata).^n),3)*handles.ScanControl.YVoltages'*cmpv(2))/matsum;      %Discrete integral for the Y-coordinate
                    centerX = sum(handles.ScanControl.XVoltages*cmpv(1)*(sum((double(scandata).^n),3)))/matsum;     %Discrete integral for X
                    centerZ = sum(handles.ScanControl.ZVoltages*cmpv(3)*(sum((permute(double(scandata), [3 1 2]).^n),3)))/matsum;   %Discrete Integral for Z
                    if isnan(centerZ)   %I've had some problems with getting NaN for centerZ, so this just keeps the z-location
                                        %steady if that happens
                        centerZ = str2double(get(handles.editPositionZ, 'String'));
                    end
                    if isnan(centerX) || isnan(centerY)
                        % If centerX or centerY returns a NaN, then no data
                        % is being acquired, so just keep everything where it is
                        centerX = str2double(get(handles.editPositionX, 'String'));
                        centerY = str2double(get(handles.editPositionY, 'String'));
                    end
                    
                    if obj.bDebug == true
                        p = [centerX centerY centerZ];
                        %useful for debugging, this plots the scan tracking
                        % sees next to the real scan
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

%                         oldVal = obj.oldVal;
%                         newVal = obj.newVal;
                        %show the xy slice at the proposed z sligthly to
                        %the right of where it is in the scan
                        cla(axesXY);
                        plot(axesXY,1);
                        imagesc(xbounds,ybounds,transpose(scandata(:,:,zi)),'Parent',axesXY);
                        
                        xlabel(axesXY,'X (�m)');
                        ylabel(axesXY,'Y (�m)');
                        title(axesXY,'Tracking XY View');
                        hold(axesXY,'on');
                        plot(axesXY,centerX,centerY,'y+','MarkerSize',20);
                        colorbar('peer',axesXY);
                        hold(axesXY,'off');
                        
                        cla(axesXZ);
                        plot(axesXZ,1);
                        imagesc(xbounds,zbounds,permute(scandata(:,yi,:),[3,1,2]),'Parent',axesXZ);
                        xlabel(axesXZ, 'X (�m)');
                        ylabel(axesXZ, 'Z (�m)');
                        title(axesXZ,'Tracking XZ View');
                        hold(axesXZ,'on');
                        plot(axesXZ,centerX,centerZ,'y+','MarkerSize',20);
                        colorbar('peer',axesXZ);
                        hold(axesXZ,'off');
                    end

                    set(handles.indicatorTrackingStatus,'String','Comparing new/old');
                    bChangePosition = ~obj.bTestNewVsOld || obj.changePositionByTracking(handles, centerX, centerY, centerZ) == true;
%                     if bChangePosition && obj.bMCLTracking
%                        %update Z
%                         set(handles.editPositionZ, 'String', num2str(centerZ));
%                         obj.updateVoltage(handles, 3, centerZ);
%                     end
                    
                    if bChangePosition
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
                        
                        % 9-17-12, 9-18-12: again, updateVoltage takes in
                        % the position in microns and will convert
                        obj.updateVoltage(handles, 1, centerX);
                        obj.updateVoltage(handles, 2, centerY);
                        obj.updateVoltage(handles, 3, centerZ);
                        
                    end
                    if obj.bDebug == true
                        if obj.trackingHistIndex == 100
                            obj.trackingHistory = circshift(obj.trackingHistory,-1);
                        end
                        
                        obj.trackingHistory(obj.trackingHistIndex,1) = str2double(get(handles.editPositionX, 'String'));
                        obj.trackingHistory(obj.trackingHistIndex,2) = str2double(get(handles.editPositionY, 'String'));
                        obj.trackingHistory(obj.trackingHistIndex,3) = str2double(get(handles.editPositionZ, 'String'));
                        
                        
                        laserX = str2double(get(handles.editPositionX, 'String'));
                        laserY = str2double(get(handles.editPositionY, 'String'));
                        laserZ = str2double(get(handles.editPositionZ, 'String'));
                        
                        
                        trackingDiffX = obj.trackingHistory(1:obj.trackingHistIndex,1) - obj.trackingHistory(1,1);
                        trackingDiffY = obj.trackingHistory(1:obj.trackingHistIndex,2) - obj.trackingHistory(1,2);
                        trackingDiffZ = obj.trackingHistory(1:obj.trackingHistIndex,3) - obj.trackingHistory(1,3);
                        
%                         %Compensate MCL stage to try to keep laser spot
%                         %fixed (3/17/14)
%                         if obj.bMCLTracking
%                             % mDAC('adjust_tip_position',-(laserX - centerX), laserY-centerY);
%                             %  -(laserX - centerX)
%                             % laserY-centerY
%                         end
                        
                        length(trackingDiffX);
                        length(1:(obj.trackingHistIndex-1));
                        if obj.trackingHistIndex >1
                        end
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
                    set(handles.buttonStartTracking,'String','Okay to stop');
                    obj.numCounts = 0;
                    obj.runCount(handles, true, handles.TrackingParameters.PostDwellTime);
                end
            end
        end
        
        %---- draw tracking square on confocal image ------------------------------------------------------
        function createTrackingCursor(obj, handles)
            %Exactly the same as the Manual Cursor, but says "Tracking
            %Cursor" instead
            currentAxes = handles.confocalAxes;
            x = str2double(get(handles.editPositionX,'String'));
            y = str2double(get(handles.editPositionY,'String'));
            
            hold(currentAxes,'on');
            obj.hTrackingCursor = plot(currentAxes,x,y,'sg',...
                       'MarkerSize',15);
            hold(currentAxes,'off');

        end
        
        %---- remove squared tracking cursor from confocal image ------------------------------------------
        function deleteTrackingCursor(obj,handles)
            %Deletes the trackin cursor
            currentAxes = handles.confocalAxes;
            if ~isempty(obj.hTrackingCursor)
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
        
        %---- changing DAQ output to new tracking position ------------------------------------------------
        function bool = changePositionByTracking(obj, handles, centerX, centerY, centerZ)
            %Perform a quick scan at the new position and one at the old
            %position. If the ammount of light collected at the new
            %position is greater then the ammount at the old position by a
            %factor dictated by the "Tracking Threshold" property, then
            %return true
            
            % 9-17-12, 9-18-12: Analog out voltages are being written so
            % the conversions are needed.
            cmpv = zeros(1,3);
            cmpv(1)=handles.configS.micronsPerVoltX;
            cmpv(2)=handles.configS.micronsPerVoltY;
            cmpv(3)=handles.configS.micronsPerVoltZ;
            cvpm = zeros(1,3);
            cvpm(1)=handles.configS.voltsPerMicronX;
            cvpm(2)=handles.configS.voltsPerMicronY;
            cvpm(3)=handles.configS.voltsPerMicronZ;
            
            % "currentScanParameters" is itself an instance of class confocalScanParameters
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
            % voltages not being updated at the start of the running count
            pause(0.5);
            obj.numCounts = 0;
            % set in tracking parameters the comparison time
            t = handles.TrackingParameters.CompDwellTime;
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
            
%             %if using MCL compensation, switch back to old x-y center
%             if obj.bMCLTracking
% 
%             end
            
        end
        
        %---- save count history --------------------------------------------------------------------------
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

