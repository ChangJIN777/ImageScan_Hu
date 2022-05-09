classdef ScanControl < handle
    % ScanControl performs the confocal scan
    %   it sets up the scan voltages, communicates with DAQ, gathering data 
    %   the from DAQ counters, updates the GUI image and saves the scans
    
    properties
%         DAQ; %handle to DAQ driver
%         ScanParameters;
%         TrackingParameters;
        currentScanParameters = [];
        lastScanParameters = [];
        currentNSamples;
        XVoltages;
        YVoltages;
        ZVoltages;
        dimA = 0;
        dimB = 0;
        dimC = 0;
        AVoltages = [];
        BVoltages = [];
        CVoltages = [];
        counterData;            %array of counter samples for current scan
        lastCounterData = [];
        indexCounterData;       %how many counter samples have been acquired in the current scan
        currentVoltageTuples    %list of X,Y voltages performed in sequence in a scan
        imageData;              %formatted scanned image
        lastImageData = [];
        cubeData = [];          %keep all 3D data for a small scan, bKeepAllData
        indexCVoltages;
        hImage;                 %image handle
        hPlot;                  %handle to 1D plot on axesCountHistory
        dutyCycle = 0.5;
        externalStop = true;
        bKeepAllData = true;
        currentTab = 1;
        bSimulatedData = false;
        scanData = [];
        scanFig = [];
        imageInfo = [];
        imageSaveCounter = 0;   % increments automatically with each time scan is done.
     
    end
    
    
    methods
        function obj = ScanControl(handles)
%             %DAQ driver for an NI data aquisition card
%             obj.DAQ = DAQ;
%             obj.ScanParameters = csp;
%             obj.TrackingParameters = cstp;
        end
        
        
        
            
        %---- perform confocal scan -----------------------------------------------------------------------   
        function [data] = performScan(obj,handles,bTracking)
            %handles         gui handles structure for ImageScan figure
            obj.externalStop = false;

            if bTracking == false
                obj.initializeScan(handles);
                if obj.externalStop
                    return
                end
            else
                obj.initializeTrackScan(handles);
            end
            if obj.currentScanParameters.bSaveData == true
                bUseCurrent = true;
                obj.imageInfo = obj.scanImageInfo(handles,bUseCurrent,bTracking);
                if isempty(obj.imageInfo)
                    obj.externalStop = true;
                end
            end
            continueScan = true;
            while continueScan
                if obj.dimC ~= 0
                    CIteratorList = 1:length(obj.CVoltages);
                else
                    CIteratorList = 1;
                end

                for iC = CIteratorList
                    if obj.externalStop == false
                        obj.indexCVoltages = iC;
                        obj.startScan(handles);
                        while (obj.externalStop == false) && (obj.isScanDone(handles) == false)
                            obj.readCounterBuffer(handles);
                            if bTracking == false       % tracking is internal, produces no output
                                obj.updateImage(handles);
                                obj.updatePositions(handles);
                            end
                            drawnow();                  %refresh image and flush event queue with stopButton callback
                            pause(0.1);                 %seconds
                        end
                        % get whatever is left in the buffer once the DAQ
                        % says it's done.
                        obj.readCounterBuffer(handles);
                        if bTracking == false
                            obj.updateImage(handles);
                        end
                        
                        if obj.bKeepAllData == true
                            if obj.dimB ~= 0 %insert current data slice
                                obj.cubeData(:,:,iC) = transpose(obj.imageData);
                            else %1D scan
                                obj.cubeData = obj.scanData;
                            end
                        end
                        obj.lastCounterData = obj.counterData;% save to use later
                        obj.clearTasks(handles);
                        obj.saveScan(handles);
                    end
                end
                obj.lastCounterData = [];
                continueScan = obj.externalStop == false ...
                    && (get(handles.checkboxScanContinuous,'Value') == true)...
                    && bTracking == false;

                obj.finishScan(handles);
            end

            obj.stopScan();
            data = obj.cubeData;
            set(handles.confocalAxes, 'YDir', 'normal');
            
            % added 4/18/2013. save automatically all new images.
            % but don't do this if we are supposed to only be tracking.
            if (bTracking == false && handles.configS.bAutoSave == true)
                disp('saving image')
                obj.AutomaticSaveScan(handles);
            end
        end
        
        function [data] = exportRawImageData(obj)
            data = obj.imageData;
        end
        %---- automatic saving on function (also automatically update the ref image for image registration tracking) ----------------------------------------------------------------
        function AutomaticSaveScan(obj,handles)
            
            imageToSave = obj.imageData;
            imageInfo1 = obj.scanImageInfo(handles,false, false); % last argument is bTracking
            if isempty(imageInfo1) == true
                return
            end
            [~, ~, ext] = fileparts(imageInfo1.file);
            switch ext
                case '.txt'
                    fid = fopen(imageInfo1.file, 'wt');
                    fprintf(fid, imageInfo1.description);
                    fprintf(fid, '\n\n');
                    fclose(fid);
                    dlmwrite(imageInfo1.file, imageToSave, '-append', 'delimiter', '\t');
                case '.csv'
                    fid = fopen(imageInfo1.file, 'wt');
                    fprintf(fid, imageInfo1.description);
                    fprintf(fid, '\n\n');
                    fclose(fid);
                    dlmwrite(imageInfo1.file, imageToSave, '-append', 'delimiter', ',');
                case '.xls'
                    xlswrite(imageInfo1.file, imageToSave);
                case {'.tif', '.tiff'}
                    imwrite(imageToSave,file,'Description',imageInfo1);
            end
            
%             % with each autosave, we update the reference image scan path for the image registration algorithm
%             set(handles.refImagePath,'String', imageInfo1.file); 
            
            %save the image also as .mat file including all paramters
            obj.SaveMatFile(handles);
            
        end
        
        %--- changing the voltage arrays into the right format for the DAQ --------------------------------
        function [VoltageTuples] = generateScanVoltages(obj)
            % voltageTuples The A (and B) voltages the DAQ will go through
            % generates a list of voltage Tuples in boustrophedon scanning
            % order, i.e. raster order with every other X voltage sequence
            % reversed
            
            % 9-17-12, 9-18-12 - no changes were needed for the
            % microns/volts conversion in this function, since the A,B,C
            % voltages have already been set in [volts]
            
            %get indices of enabled scan dimensions (X,Y,Z)
            enabledDims = find(obj.currentScanParameters.bEnable == 1);
            
            if length(enabledDims) == 1 % a 1D scan
                VoltageTuples = obj.AVoltages; %only need one voltage (A) at a time
            else
                Va = obj.AVoltages;
                Vb = obj.BVoltages;
                %store voltage Tuples where Row# gives A position, Col# gives B
                %position, and Page# is the voltage for A or B galvos
                VoltageMatrix = zeros(length(Va),length(Vb),2);

                %generate X voltages that vary in Row# but not Col#
                VoltageMatrix(:,:,1) = Va(:) * ones(1,length(Vb));
                %generate Y voltages that vary in Col# but not Row#
                VoltageMatrix(:,:,2) = ones(length(Va),1)*Vb;
                %Reverse every other X column, so each scanning position is
                %close to the next position.
                VoltageMatrix(:,2:2:end,1)=flipdim(VoltageMatrix(:,2:2:end,1),1);
                %z 2:2:end

                %reshape into an ordered list of Tuples, first column is X voltage,
                %second is Y
                VoltageTuples = reshape(VoltageMatrix,[],2,1);
                if obj.dimC ~= 0 && mod(obj.indexCVoltages,2)==0
                    VoltageTuples = flipud(VoltageTuples);
                end
            end
            obj.currentVoltageTuples = VoltageTuples;
        end %generateScanVoltages
 
%         %---- this function seems to be unused ------------------------------------------------------------
%         function updateRunningCount(obj,handles)
%             lastSample = 0;
%             if obj.indexCounterData > 1 && obj.indexCounterData < length(obj.counterData)
%                 lastSample=obj.counterData(obj.indexCounterData);
%                 if mod(obj.indexCVoltages,2) == 1
%                     lastSample = lastSample - obj.counterData(obj.indexCounterData-1);
%                 else
%                     lastSample = lastSample - obj.counterData(obj.indexCounterData+1);
%                 end
%             end
%             lastSample = abs(lastSample) /(1000*obj.currentScanParameters.DwellTime);
%             set(handles.editRunningCount,'String',num2str(lastSample));
%             handles.CursorControl.addCountToHistory(handles,lastSample);
%         end
        
        %---- this function seems to have lost it's usefulness.... ----------------------------------------
        function updatePositions(obj,handles)%%%generalize and fix
                mpvz = zeros(1,3);
                mpvz(1) = handles.configS.micronsPerVoltX;
                mpvz(2) = handles.configS.micronsPerVoltY;
                mpvz(3) = handles.configS.micronsPerVoltZ;
            if obj.indexCounterData >= 1 && obj.indexCounterData <= size(obj.currentVoltageTuples, 1)
                if obj.dimC ~= 0
                    positionC = obj.CVoltages(obj.indexCVoltages);
                    strC = sprintf('%.2f',positionC*mpvz(3));
                    set(handles.editPositionZ,'String',strC); 
                end
            end
        end    
        
        %--- initialize the scan (set up voltages, dimensions to scan and image)----------------------------
        function initializeScan(obj,handles)
           
            %save the current parameters in case the user changes the settings during the scan
            obj.currentScanParameters = handles.ScanParameters;
            scan = obj.currentScanParameters;   %abbreviate for use later
            
            ImageSaveCounter =  sprintf('%06d', str2double(obj.imageSaveCounter)+1);
            if ~strcmp(ImageSaveCounter,'000001')
                set(handles.inputSaveImageFileNum,'String', ImageSaveCounter);
            end

            NEnabledDims = sum(scan.bEnable);%the number of dimensions of the scan

            obj.initializeDimensions(handles);

            obj.initializeVoltages(handles);
            
            Na = scan.NPoints(obj.dimA);
            if obj.dimB ~= 0
                Nb = scan.NPoints(obj.dimB);
            else
                Nb = 1;
            end
            
            if obj.dimC ~= 0
                Nc = scan.NPoints(obj.dimC);
            else
                Nc = 1;
            end
            obj.currentNSamples = Na*Nb + 1;
            
            %number of samples = Na+Nb+1 because the first counter value
            %won't be at the first desired position, so it will be thrown
            %out, the last sample needs to be at the last desired position
            
            %if the entire N dimension scan is small enough, save the whole
            %thing, if not only keep one slice at a time
            obj.bKeepAllData = Na*Nb*Nc < 10000;
            if isempty(obj.lastScanParameters) == true ... %don't remove old scan, overwrite it
                    || obj.currentScanParameters.haveSameRegion(obj.lastScanParameters) == false
                obj.counterData = zeros(obj.currentNSamples,1);
            end
            obj.counterData = zeros(obj.currentNSamples,1);
            obj.lastScanParameters = ConfocalScanParameters();
            obj.lastScanParameters.ImportScan(obj.currentScanParameters);%save for next time
            
            if NEnabledDims > 1
                obj.imageData = zeros(Nb,Na);
            else
                obj.scanData = ones(Na); 
            end
            
            if obj.bKeepAllData == true
                obj.cubeData = zeros(Na,Nb,Nc);
            end

            %set up image display
            axes(handles.confocalAxes);

            %do not change colormap scaling when new data is put in
            if NEnabledDims > 1
                % 9-17-12, 9-18-12: the scan.Min/MaxValues are already in
                % microns here, so no need to convert.
                cla(handles.confocalAxes)
                xlim = [scan.MinValues(obj.dimA) scan.MaxValues(obj.dimA)];
                ylim = [scan.MinValues(obj.dimB) scan.MaxValues(obj.dimB)];
                set(handles.confocalAxes, 'XLim', xlim);
                set(handles.confocalAxes, 'YLim', ylim);
                line([-50 -50;nan nan;50 50],[-50 -50;nan nan;50 50], 'linewidth', eps(0), 'color', 'w')
                obj.hImage = imagesc('XData', [scan.MinValues(obj.dimA),scan.MaxValues(obj.dimA)],...
	        		'YData', [scan.MinValues(obj.dimB),scan.MaxValues(obj.dimB)],...
                    'CData', obj.imageData);
                colorbar('peer', handles.confocalAxes);
            	set(handles.confocalAxes,'YDir','normal');
                set(handles.confocalAxes,'FontSize',9);

                xlabel(handles.confocalAxes,[DAQManager.strDims(obj.dimA) ' [µm]']);
                ylabel(handles.confocalAxes,[DAQManager.strDims(obj.dimB) ' [µm]']);
            else
                % 9-17-12, 9-18-12 - here the plotting has been done with
                % the obj.AVoltages, which I have as an actual voltage
                % (volts) still, so need ot convert such that we are
                % plotting the 1D scan against microns.
                cla(handles.axesCountHistory)
                mpv1D = zeros(1,3);
                mpv1D(1) = handles.configS.micronsPerVoltX;
                mpv1D(2) = handles.configS.micronsPerVoltY;
                mpv1D(3) = handles.configS.micronsPerVoltZ;
                
                obj.hPlot = plot(handles.axesCountHistory, obj.AVoltages*mpv1D(obj.dimA), obj.scanData,'red');
                set(handles.axesCountHistory,'FontSize',9);
                ylabel(handles.axesCountHistory,'[kcounts/s]');
                xlabel(handles.axesCountHistory,['[µm]']);
            end

        end %initializeScan
        
        %---- initialize the dimensions that are scaned ---------------------------------------------------
        function initializeDimensions(obj,handles)
            
            %by default disable all dimensions
            obj.dimA = 0;
            obj.dimB = 0;
            obj.dimC = 0;
            obj.AVoltages = [];
            obj.BVoltages = [];
            obj.CVoltages = [];

            %create a list of enabled dimension indices
            enabledDims = find(obj.currentScanParameters.bEnable == 1);
            
            NEnabledDims = length(enabledDims);%the number of dimensions of the scan

            %the options for the scan are X,Y,Z,XY,XZ,YZ,XYZ
            %assign A to be the first enabled sequence, options are X,Y,Z
            obj.dimA = enabledDims(1);
            %if there's a second, assign to B, options are Y,Z
            if NEnabledDims > 1
                obj.dimB = enabledDims(2);
            end
            %if a third, assign to C, only option is Z
            if NEnabledDims > 2
                obj.dimC = enabledDims(3);
            end
            
            % dimension X can only be assigned to A, since it is highest priority
            % dimension Y can be A (if X is disabled) or B
            % dimension Z can be A (X,Y disabled), B (X xor Y disabled), or C (X,Y enabled)
        end
        
        %---- create voltage array to send to DAQ ---------------------------------------------------------
        function initializeVoltages(obj,handles)
            scan = obj.currentScanParameters;%abbreviate for use later

            %create a list of enabled dimension indices
            enabledDims = find(obj.currentScanParameters.bEnable==1);
            
            NEnabledDims = length(enabledDims);%the number of dimensions of the scan            

            %9-17-12, 9-18-12, added microns/volts conversion
            mpv = zeros(1,3);
            mpv(1) = handles.configS.micronsPerVoltX;
            mpv(2) = handles.configS.micronsPerVoltY;
            mpv(3) = handles.configS.micronsPerVoltZ;
            vpm = zeros(1,3);
            vpm(1) = handles.configS.voltsPerMicronX;
            vpm(2) = handles.configS.voltsPerMicronY;
            vpm(3) = handles.configS.voltsPerMicronZ;
            
            %if using the zoombox to zoom 2D or 3D, set the A and B (x and y on
            %graph) limits to the currently displayed limits
            if get(handles.checkUseZoomboxLimits, 'Value') ==  true ...
                    && NEnabledDims > 1 ...
                    && isempty(obj.lastScanParameters) == false ...
                    && all(scan.bEnable == obj.lastScanParameters.bEnable)
                xlim = sort(get(handles.confocalAxes, 'XLim'));
                ylim = sort(get(handles.confocalAxes, 'YLim'));
                if xlim(1) < round(handles.configS.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA)*1000)/1000
                    xlim(1) = handles.configS.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA);
                end
                if xlim(2) > round(handles.configS.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA)*1000)/1000
                    xlim(2) = handles.configS.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA);
                end
                if ylim(1) < round(handles.configS.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimB)*1000)/1000
                    ylim(1) = handles.configS.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimA);
                end
                if ylim(2) > round(handles.configS.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB)*1000)/1000
                    ylim(2) = handles.configS.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB);
                end
                scan.MinValues(obj.dimA) = xlim(1);
                scan.MinValues(obj.dimB) = ylim(1);
                scan.MaxValues(obj.dimA) = xlim(2);
                scan.MaxValues(obj.dimB) = ylim(2);
            end
            
            %generate Voltage vectors for all enabled dimensions
            % 9-17-12,9-18-12 - below is where we finally want the lists
            % of voltages instead of the microns, use "vpm" vector. Here I
            % will have the "Vx, Vy, Vz" still in microns and convert
            % after, so that obj.X(Y,Z)Voltages are actually in volts
            
            %%%%%% X - voltages %%%%%%
            if scan.bEnable(handles.DAQManager.X) == true
                Vx = linspace(scan.MinValues(handles.DAQManager.X),scan.MaxValues(handles.DAQManager.X),scan.NPoints(handles.DAQManager.X));
                Vx = Vx + scan.OffsetValues(handles.DAQManager.X); %add offset for calibrated center
                obj.XVoltages = Vx*vpm(handles.DAQManager.X);
                
                % add a check to remove all values that are out of range in
                % case user asks for too large image (04/2019-SB)
                dispOn = 0;
                if max(obj.XVoltages) > handles.configS.xMaxVolts
                    [~ ,idx] = find(obj.XVoltages > handles.configS.xMaxVolts);
                    obj.XVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(1) = obj.currentScanParameters.NPoints(1) - length(idx);
                    obj.currentScanParameters.MaxValues(1) = max(obj.XVoltages)*mpv(1);
                    dispOn = 1;
                end
                
                if min(obj.XVoltages) < handles.configS.xMinVolts
                    [~ ,idx] = find(obj.XVoltages < handles.configS.xMinVolts);
                    obj.XVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(1) = obj.currentScanParameters.NPoints(1) - length(idx);
                    obj.currentScanParameters.MinValues(1) = min(obj.XVoltages)*mpv(1);
                    dispOn = 1;
                end
                if dispOn == 1
                    disp('chosen X scan window was larger than possible - scanning a smaller window now')
                end 
                
            else
                obj.XVoltages = [];
            end
            
            %%%% Y - voltages %%%%%
            if scan.bEnable(handles.DAQManager.Y) == true
                Vy = linspace(scan.MinValues(handles.DAQManager.Y),scan.MaxValues(handles.DAQManager.Y),scan.NPoints(handles.DAQManager.Y));
                Vy = Vy + scan.OffsetValues(handles.DAQManager.Y);
                obj.YVoltages = Vy*vpm(handles.DAQManager.Y);
                
                % add a check to remove all values that are out of range in
                % case user asks for too large image (04/2019-SB)
                dispOn = 0;
                if max(obj.YVoltages) > handles.configS.yMaxVolts
                    [~ ,idx] = find(obj.YVoltages > handles.configS.yMaxVolts);
                    obj.YVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(2) = obj.currentScanParameters.NPoints(2) - length(idx);
                    obj.currentScanParameters.MaxValues(2) = max(obj.YVoltages)*mpv(2);
                    dispOn = 1;
                end
                
                if min(obj.YVoltages) < handles.configS.yMinVolts
                    [~ ,idx] = find(obj.YVoltages < handles.configS.yMinVolts);
                    obj.YVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(2) = obj.currentScanParameters.NPoints(2) - length(idx);
                    obj.currentScanParameters.MinValues(2) = min(obj.YVoltages)*mpv(2);
                    dispOn = 1;
                end
                if dispOn == 1
                    disp('chosen Y scan window was larger than possible - scanning a smaller window now')
                end 
                
            else
                obj.YVoltages = [];
            end
            
            %%%%%%% Z - voltages
            if scan.bEnable(handles.DAQManager.Z) == true
                Vz = linspace(scan.MinValues(handles.DAQManager.Z),scan.MaxValues(handles.DAQManager.Z),scan.NPoints(handles.DAQManager.Z));
                Vz = Vz + scan.OffsetValues(handles.DAQManager.Z);
                obj.ZVoltages = Vz*vpm(handles.DAQManager.Z); 
                
                % add a check to remove all values that are out of range in
                % case user asks for too large image (04/2019-SB)
                dispOn = 0;
                if max(obj.ZVoltages) > handles.configS.zMaxVolts
                    [~ ,idx] = find(obj.ZVoltages > handles.configS.zMaxVolts);
                    obj.ZVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(3) = obj.currentScanParameters.NPoints(3) - length(idx);
                    obj.currentScanParameters.MaxValues(3) = max(obj.ZVoltages)*mpv(3);
                    dispOn = 1;
                end
                
                if min(obj.ZVoltages) < handles.configS.zMinVolts
                    [~ ,idx] = find(obj.ZVoltages < handles.configS.zMinVolts);
                    obj.ZVoltages(idx) = [];        % empty those values
                    obj.currentScanParameters.NPoints(3) = obj.currentScanParameters.NPoints(3) - length(idx);
                    obj.currentScanParameters.MinValues(3) = min(obj.ZVoltages)*mpv(1);
                    dispOn = 1;
                end
                if dispOn == 1
                    disp('chosen Z scan window was larger than possible - scanning a smaller window now')
                end 
                
            else
                obj.ZVoltages = [];
            end

            
            %now match X,Y,Z voltages with A,B,C voltages
            % 9-17-12, 9-18-12  A,B,C voltages are also in volts now as the
            % above are in volts
            % set the first voltage...
            switch enabledDims(1)
                case handles.DAQManager.X
                    obj.AVoltages = obj.XVoltages;
                case handles.DAQManager.Y
                    obj.AVoltages = obj.YVoltages;
                case handles.DAQManager.Z
                    obj.AVoltages = obj.ZVoltages;
            end
            % set the second voltage if 2D, 3D....
            if length(enabledDims) > 1
                switch enabledDims(2)
                    case handles.DAQManager.Y
                        obj.BVoltages = obj.YVoltages;
                    case handles.DAQManager.Z
                        obj.BVoltages = obj.ZVoltages;
                end
            end
            % set the third voltage if 3D, always z...
            if NEnabledDims > 2
                obj.CVoltages = obj.ZVoltages;
            end
        end
        
        
        %----  update Image -------------------------------------------------------------------------------
        function updateImage(obj,handles)

            if obj.dimB ~= 0
                set(obj.hImage,'CData',obj.imageData);
                if get(handles.checkboxAutoColorScale,'Value') == true
                    caxis(handles.confocalAxes, 'auto');
                end   
            else
                set(obj.hPlot,'YData',obj.scanData);
            end
            
        end
        
        %--- Creates and starts DAQ tasks necessary for a scan --------------------------------------------
        function startScan(obj,handles)
            
            dwell = obj.currentScanParameters.DwellTime;%time in seconds
            %to laser position gathering counter data before moving on
            NSamples = obj.currentNSamples;
            
            if mod(obj.indexCVoltages,2)==0
                obj.indexCounterData = obj.currentNSamples+1;
            else
                obj.indexCounterData = 0;%start filling counter Data array at the beginning
            end
            
            if all(obj.currentScanParameters.bEnable) == true
                handles.DAQManager.DAQ.AnalogOutVoltages(obj.dimC) = obj.ZVoltages(obj.indexCVoltages);
                handles.DAQManager.DAQ.WriteAnalogOutLine(obj.dimC);
            end
            
            handles.DAQManager.DAQ.ClearAllTasks();
            
            %Create a pulse train to act as a clock to coordinate the
            %position movements and counter measurements
            handles.DAQManager.DAQ.CreateTask('PulseTrain');
            clockFrequency = 1/dwell;
            clockLine = 1;
            handles.DAQManager.DAQ.ConfigureClockOut('PulseTrain', clockLine, clockFrequency, obj.dutyCycle);
           
            %set up X position voltages and Y position voltages for the
            %entire scan
            handles.DAQManager.DAQ.CreateTask('VoltageOut');
            obj.generateScanVoltages();%stores values in obj.currentVoltageTuples
            if obj.dimB ~= 0
                VoltageLines = [obj.dimA,obj.dimB];
            else
                VoltageLines = obj.dimA;
            end
            handles.DAQManager.DAQ.ConfigureVoltageOut('VoltageOut',VoltageLines,obj.currentVoltageTuples(:), clockLine);
            %[VoltagesLines selects obj.DAQ.AnalogOutVoltages(obj.dimA) for the A voltage
            %and obj.DAQ.AnalogOutVoltages(obj.dimB) for B for the 2D slice scan
            
            %set counter to save a sample at each position(voltage pair) visited
            counterLine = 1;
            handles.DAQManager.DAQ.CreateTask('Counter');
            handles.DAQManager.DAQ.ConfigureCounterIn('Counter',counterLine,NSamples);
            handles.DAQManager.DAQ.StartTask('Counter');
            
           
           
            % wait for tasks to start and for z position to move
            pause(0.3);
            handles.DAQManager.DAQ.StartTask('VoltageOut');

            % start the sample clock
            if obj.externalStop == false
            %because of pause(.3), we need to check if externally stopped
                handles.DAQManager.DAQ.StartTask('PulseTrain');
            end
        end %startScan
        
        %---- query if taak is done -----------------------------------------------------------------------
        function isScanDone = isScanDone(~,handles)
            isScanDone = handles.DAQManager.DAQ.IsTaskDone('Counter');
        end

        %---- read counter buffer from DAQ ----------------------------------------------------------------
        function [scanData] = readCounterBuffer(obj,handles)
            NSamplesAvailable = handles.DAQManager.DAQ.GetAvailableSamples('Counter');

            if NSamplesAvailable > 0 
                %insert samples in counter data array
                %index of first new sample
                if mod(obj.indexCVoltages,2) == 1
                    iSample = obj.indexCounterData + 1;
                    jSample = obj.indexCounterData + NSamplesAvailable; %index of last new sample
                    increment = 1;
                else
                    iSample = obj.indexCounterData - 1;
                    jSample = obj.indexCounterData - NSamplesAvailable;
                    increment = -1;
                end
             
                %insert samples
               
                obj.counterData(iSample:increment:jSample) = handles.DAQManager.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                %next new sample will go at index jSample + 1
                obj.indexCounterData = jSample;
                %turn the counter data array into an image
                scanData = obj.formatImageData();
            else
                scanData = [];
            end
        end
        
        %--- create image matrix --------------------------------------------------------------------------
        function [scanData] = formatImageData(obj)
            if obj.indexCounterData > 0 && obj.indexCounterData <= obj.currentNSamples
                %make a matrix with the final image size
                %The counter increases cumulatively, use diff to find counts
                %that occured while at individual positions
                %and convert to kiloCounts per second
                %diff also helps to discard the useless first counter value
                scanData = abs(diff(obj.counterData))/(1000*obj.currentScanParameters.DwellTime);
                if isempty(obj.lastCounterData) == false
                    lastScanData = abs(diff(obj.lastCounterData))/(1000*obj.currentScanParameters.DwellTime);
                     if obj.indexCounterData > 1 && obj.indexCounterData < obj.currentNSamples
                        if mod(obj.indexCVoltages,2) == 1
                                scanData(obj.indexCounterData:end) = lastScanData(obj.indexCounterData:end);
                        else
                                scanData(1:obj.indexCounterData-1) = lastScanData(1:obj.indexCounterData-1);
                        end
                    end
                else
                
                    %set all pixels that do not contain data to the minimum data
                    %values
                    if obj.indexCounterData > 1 && obj.indexCounterData < obj.currentNSamples
                        if mod(obj.indexCVoltages,2) == 1
                                minData = min(scanData(1:obj.indexCounterData-1));
                                scanData(obj.indexCounterData:end) = minData;
                        else
                                minData = min(scanData(obj.indexCounterData:end));
                                scanData(1:obj.indexCounterData-1) = minData;
                        end
                    end
                end
                %because reshape prioritizes row->col, make X vary with Row# and
                %Y vary with Col#, then transpose
                obj.scanData = scanData;
                if obj.dimB ~= 0
                    scanData = reshape(scanData,obj.currentScanParameters.NPoints(obj.dimA),obj.currentScanParameters.NPoints(obj.dimB));

                    %reverse the X columns since the data was collected in
                    %boustrophedon scanning order.
                    scanData(:,2:2:end)=flipud(scanData(:,2:2:end));
                    scanData = transpose(scanData);
                end
                obj.imageData = scanData;
            else
                scanData = [];
            end
        end
 
        %---- clear DAQ tasks -----------------------------------------------------------------------------
        function clearTasks(~,handles)
            %clear scan tasks
            handles.DAQManager.DAQ.ClearTask('Counter');
            handles.DAQManager.DAQ.ClearTask('VoltageOut');
            handles.DAQManager.DAQ.ClearTask('PulseTrain');
            
            
            
        end
        
        %--- end the confocal scan ------------------------------------------------------------------------
        function finishScan(obj,handles)
            obj.clearTasks(handles);
            % move the galvo position to the pre-scan cursor position
            Vx = str2double(get(handles.editPositionX,'String'));
            Vy = str2double(get(handles.editPositionY,'String'));
            Vz = str2double(get(handles.editPositionZ,'String'));
            V = [Vx Vy Vz];
            % 9-17-12, 9-18-12: this V will be in microns. convert before
            % writing to the analog out.
            vpm = zeros(1,3);
            vpm(1) = handles.configS.voltsPerMicronX;
            vpm(2) = handles.configS.voltsPerMicronY;
            vpm(3) = handles.configS.voltsPerMicronZ;
            
            handles.DAQManager.DAQ.AnalogOutVoltages(obj.dimA) = V(obj.dimA)*vpm(obj.dimA);
            handles.DAQManager.DAQ.WriteAnalogOutLine(obj.dimA);

            if obj.dimB ~= 0
                handles.DAQManager.DAQ.AnalogOutVoltages(obj.dimB) = V(obj.dimB)*vpm(obj.dimB);
                handles.DAQManager.DAQ.WriteAnalogOutLine(obj.dimB);
            end
            
            if obj.dimC ~= 0
                
                handles.DAQManager.DAQ.AnalogOutVoltages(obj.dimC) = V(obj.dimC)*vpm(obj.dimC);
                handles.DAQManager.DAQ.WriteAnalogOutLine(obj.dimC);
            end
        end
        
        %---- stop scan by chaning the external stop state ------------------------------------------------
        function stopScan(obj)
            obj.externalStop = true;
        end
        
        %---- clean up ------------------------------------------------------------------------------------
        function delete(obj,handles)
            %clear all NI DAQ tasks
            handles.DAQManager.DAQ.ClearAllTasks();
            %set all output voltages to zero, so we do not continue sending
            %voltages after the program terminates.
            handles.DAQManager.DAQ.AnalogOutVoltages = zeros(length(obj.DAQ.AnalogOutVoltages));
            handles.DAQManager.DAQ.WriteAnalogOutAllLines();
        end
        
        %--- copy current confocal scan parameters --------------------------------------------------------
        function setParameters(obj, S)
            obj.currentScanParameters = S;
        end
        
        %---- initialize tracking scan --------------------------------------------------------------------
        function initializeTrackScan(obj,handles)
            
            obj.dimA = 1;
            obj.dimB = 2;
            obj.dimC = 3;
            %save the current parameters in case the user changes the settings during the scan
            obj.currentScanParameters = handles.TrackingParameters;
            
            obj.currentScanParameters.OffsetValues = [str2double(get(handles.editPositionX, 'String')) ...
                str2double(get(handles.editPositionY, 'String'))...
                str2double(get(handles.editPositionZ, 'String'))];
            
            obj.currentNSamples = obj.currentScanParameters.NPoints(obj.dimA)*obj.currentScanParameters.NPoints(obj.dimB) + 1;
            %number of samples = Nx+Ny+Nz+1 because the first counter value
            %won't be at the first desired position, so it will be thrown
            %out, the last sample needs to be at the last desired position
            obj.counterData = 1:obj.currentNSamples;
            obj.imageData = zeros(obj.currentScanParameters.NPoints(obj.dimB),...
                obj.currentScanParameters.NPoints(obj.dimA));
            

            % 9-17-12, 9-18-12: this V will be in microns. convert before
            % writing to the "obj.XVoltages" and "obj.AVoltages"
            % so again, Vx, Vy, Vz themselves stay in [microns]
            mpv = zeros(1,3);
            mpv(1) = handles.configS.micronsPerVoltX;
            mpv(2) = handles.configS.micronsPerVoltY;
            mpv(3) = handles.configS.micronsPerVoltZ;
            vpm = zeros(1,3);
            vpm(1) = handles.configS.voltsPerMicronX;
            vpm(2) = handles.configS.voltsPerMicronY;
            vpm(3) = handles.configS.voltsPerMicronZ;
            
            scan = obj.currentScanParameters;
            Vx = linspace(scan.MinValues(obj.dimA),scan.MaxValues(obj.dimA),scan.NPoints(obj.dimA));
            Vx = Vx + scan.OffsetValues(handles.DAQManager.X);
            Vx([find(Vx>handles.configS.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA)) find(Vx<handles.configS.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA))]) = [];
            obj.XVoltages = Vx*vpm(obj.dimA);
            obj.AVoltages = Vx*vpm(obj.dimA);
            
            Vy = linspace(scan.MinValues(obj.dimB),scan.MaxValues(obj.dimB),scan.NPoints(obj.dimB));
            Vy([find(Vy>handles.configS.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB)) find(Vy<handles.configS.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimB))]) = [];
            Vy = Vy + scan.OffsetValues(handles.DAQManager.Y);
            obj.YVoltages = Vy*vpm(obj.dimB);
            obj.BVoltages = Vy*vpm(obj.dimB);
            
            Vz = linspace(scan.MinValues(obj.dimC), scan.MaxValues(obj.dimC), scan.NPoints(obj.dimC));
            Vz = Vz + scan.OffsetValues(handles.DAQManager.Z);
            Vz([find(Vz>handles.configS.AnalogOutMaxVoltages(obj.dimC)*mpv(obj.dimC)) find(Vz<handles.configS.AnalogOutMinVoltages(obj.dimC)*mpv(obj.dimC))]) = [];
            obj.ZVoltages = Vz*vpm(obj.dimC);
            obj.CVoltages = Vz*vpm(obj.dimC);
            
            % this holds PL data in the cube of voltage points
            obj.cubeData = zeros(length(Vy),length(Vx),length(Vz));
        end
        
        %---- deal with paramters, eg. adjust saving folder, update filenumber, ... --------------------------------
        % setting the meta data for the image files
        function imageInfo = scanImageInfo(obj,handles,bCurrent,bTracking)
            %%%%
            % update filepath and filename automatically to current date
            % and add one to last saved file number (update 04/19/17 SB)
            d = datestr(now,'yyyy_mmm_dd');
            fileDateFolder = get(handles.inputSaveImagePath,'String');

            if ~strcmp(fileDateFolder(end-11:end-1),d) % compare date strings if not equal update in GUI and create folder
                newfileDateFolder = [fileDateFolder(1:end-12) d '\']; % warning, in case the whole date save path structure changes, this line might mess up and might need to be reprogrammed    
                set(handles.inputSaveImagePath,'String', newfileDateFolder);
                fileDateFolder = newfileDateFolder;
            end
            if exist(fileDateFolder,'dir') ~= 7 % if directory exists matlab returns 7
                mkdir(fileDateFolder)
            end

            
            allfiles = dir([fileDateFolder '*.mat']);
            [~,newestIndex] = max([allfiles.datenum]); % find the newest file
            if isempty(newestIndex)
                ImageSaveCounter = '000000';
            else
                newestFile = allfiles(newestIndex).name;
                k = strfind(newestFile,'_');
                if max(size(k))>= 2
                    ImageSaveCounter = newestFile(k(end-2)+1:k(end-1)-1);
                else
                    ImageSaveCounter = newestFile(k(end-1)-7:k(end-1)-1); % this case should not happen but if it does, just assume the number is 6 digits long
                end
            end
            ImageSaveCounter = sprintf('%06d', str2double(ImageSaveCounter)+1); % add 1 to last counter

            set(handles.inputSaveImageFileNum,'String', ImageSaveCounter);
            obj.imageSaveCounter = ImageSaveCounter;

            % pass parameters to old naming and clear up
            myFormattedPathname = get(handles.inputSaveImagePath,'String');
            myFormattedFilePrefix = get(handles.inputSaveImageFilePrefix,'String');
            myFormattedFileNum = ImageSaveCounter;            
                        
            clear fileDateFolder d newestIndex k* newestFile* 
            clear d fileDateFolder newfileDateFolder

            %%%%            
            if bTracking == false
                  filename = [myFormattedFilePrefix myFormattedFileNum '.txt'];
                  fpath = myFormattedPathname;
            else
                filename = obj.currentScanParameters.filename;
                fpath = pwd;
            end
            
            if bCurrent
                scan = handles.ScanControl.currentScanParameters;
            else
                scan = handles.ScanControl.lastScanParameters;
            end
            
            bHaveParams = ~isempty(scan);
            if ischar(filename) && bHaveParams
                description = '';
                description = [description 'Timestamp: ' datestr(now) ' $' newline];
                description = [description 'DwellTime: ' ...
                    num2str(scan.DwellTime) ' s $' newline];

                strDimension = 'XYZ';
                for iDimension=1:3
                    description = [description 'Min' strDimension(iDimension) ': ' ...
                        num2str(scan.MinValues(iDimension)) ' $' newline];
                    description = [description 'Max' strDimension(iDimension) ': ' ...
                        num2str(scan.MaxValues(iDimension)) ' $' newline];
                    description = [description 'Steps' strDimension(iDimension) ': ' ...
                        num2str(scan.NPoints(iDimension)) ' $' newline];
                    description = [description 'Offset' strDimension(iDimension) ': ' ...
                        num2str(scan.OffsetValues(iDimension)) ' $' newline];
                end

                file = [fpath filename];
                imageInfo.file = file;
                imageInfo.description = description;
            else
                imageInfo = [];
            end
        end
                    
        %---- saving function to .txt file ----------------------------------------------------------------
        function saveScan(obj,handles) %#ok<*INUSD>
            if obj.currentScanParameters.bSaveData == true && ~isempty(obj.imageInfo)
                try
                imageToSave = uint16(obj.imageData);
                if obj.indexCVoltages == 1
                    writemode = 'overwrite';
                else
                    writemode = 'append';
                end
                if ~isempty(obj.imageInfo.file)
                    imwrite(imageToSave,obj.imageInfo.file,'Description',obj.imageInfo.description,'WriteMode',writemode);
                end
                catch
                    %useless save scancrashed my measurement
                end
            end
        end
        
        %---- saving function to .mat file with all parameters --------------------------------------------
        function SaveMatFile(obj,handles) %function to save Image files as .mat file
%             [Tmagnet, Tsample] = readOxfordTemp;
%             [Bx,By,Bz] = readMagField;
            enAxis = obj.currentScanParameters.bEnable;
            
%             Image.param.FileName = [get(handles.inputSaveImageFilePrefix,'String') get(handles.inputSaveImageFileNum,'String') '_' datestr(now,'yyyymmdd_HHMM')] ;
Image.param.FileName = [get(handles.inputSaveImageFilePrefix,'String') get(handles.inputSaveImageFileNum,'String')] ;
            Image.param.FilePath = get(handles.inputSaveImagePath,'String');
            Image.param.enableAxis = enAxis; % enabled scan axis [x y z], 1 = enabled, 0 = disabled
            Image.param.NPoints = obj.currentScanParameters.NPoints.*enAxis; %number of points per axis
            Image.param.XAxisMicrons = [obj.currentScanParameters.MinValues(1) obj.currentScanParameters.MaxValues(1)]*enAxis(1); % in [micrometer]
            Image.param.YAxisMicrons = [obj.currentScanParameters.MinValues(2) obj.currentScanParameters.MaxValues(2)]*enAxis(2); % in [micrometer]
            Image.param.ZAxisMicrons = [obj.currentScanParameters.MinValues(3) obj.currentScanParameters.MaxValues(3)]*enAxis(3); % in [micrometer]
            Image.param.DwellTime = obj.currentScanParameters.DwellTime; % in [s]
            Image.param.ConfocalSpotPosition = [str2double(get(handles.editPositionX,'String')) str2double(get(handles.editPositionY,'String')) str2double(get(handles.editPositionZ,'String'))]; % cursor position in [micrometer]
            Image.param.OffsetValues = obj.currentScanParameters.OffsetValues;
%             Image.param.Tsample = Tsample; % sample temperature in [K]
%             Image.param.Tmagnet = Tmagnet; % magnet temperature in [K]
%             Image.param.magField = [Bx By Bz]; % magnetic field in [G]
            Image.param.tipDiamond = get(handles.tipDiamond,'String');
            Image.param.sample = get(handles.sample,'String');
            Image.param.opticalP = str2double(get(handles.greenPowerString, 'String'))*1e6; % optical power in [W]
            
            Image.param.configParams.xMicronsperVolt = handles.configS.micronsPerVoltX; % configured micrometer to volts conversion
            Image.param.configParams.yMicronsperVolt = handles.configS.micronsPerVoltY; % configured micrometer to volts conversion
            Image.param.configParams.zMicronsperVolt = handles.configS.micronsPerVoltZ; % configured micrometer to volts conversion
            Image.param.configParams.xMinVolts = handles.configS.xMinVolts; % configured max and min voltage values
            Image.param.configParams.xMaxVolts = handles.configS.xMaxVolts;
            Image.param.configParams.yMinVolts = handles.configS.yMinVolts;
            Image.param.configParams.yMaxVolts = handles.configS.yMaxVolts;
            Image.param.configParams.zMinVolts = handles.configS.zMinVolts;
            Image.param.configParams.zMaxVolts = handles.configS.zMaxVolts;
            Image.param.ImageScanVersion = num2str(handles.version); % software version              

            Image.data.scan = obj.imageData; % [kcounts/point]
            Image.data.xAxis = obj.XVoltages.*handles.configS.micronsPerVoltX;
            Image.data.yAxis = obj.YVoltages.*handles.configS.micronsPerVoltY;
            Image.data.zAxis = obj.ZVoltages.*handles.configS.micronsPerVoltZ;
              
            save([Image.param.FilePath Image.param.FileName '.mat'],'Image')
            clear B* T* enAxis Image
        end    
            
    end %methods
    
end %classdef
