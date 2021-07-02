classdef ScanControl < handle
    %ScanControl performs an image scan
    %   communicates with DAQ and gui to perform a galvo scan, while
    %   gathering data from DAQ counters
    
    properties
        DAQ; %handle to DAQ driver
        ScanParameters;
        TrackingParameters;
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
        counterData;%array of counter samples for current scan
        lastCounterData = [];
        indexCounterData;%how many counter samples have been acquired in the current scan
        currentVoltageTuples %list of X,Y voltages performed in sequence in a scan
        imageData;%formatted scanned image
        lastImageData = [];
        cubeData = [];%keep all 3D data for a small scan, bKeepAllData
        indexCVoltages;
        hImage;%image handle
        hPlot;%handle to 1D plot on axesCountHistory
        dutyCycle = 0.5;
        externalStop = true;
        bKeepAllData = true;
        currentTab = 1;
        bSimulatedData = false;
        scanData = [];
        scanFig = [];
        imageInfo = [];
        imageSaveCounter = 0; % increments automatically with each time scan is done.
        
        figAnalogScan = 491482; %figure identifier
        axesAnalog = 491293;
        aImage; % analog voltage image handle
        bAnalogScan = false;
        analogData; % array of read out voltages in the scan
        indexAnalogData; % counter for how many scan samples Matlab has seen
        analogImageData; %formatted analog voltage image data
        lastAnalogData=[];
        
    end %properties
    
    methods

        function obj = ScanControl(DAQ,csp,cstp)
            %DAQ driver for an NI data aquisition card
            obj.DAQ = DAQ;
            obj.ScanParameters = csp;
            obj.TrackingParameters = cstp;
%             obj.TrackingParameters(1).NPoints = [7 7 7];
%             
%             obj.TrackingParameters(1).bEnable = [1 1 1];
%             obj.TrackingParameters(1).MinValues = [-.1 -.1 -.1];
%             obj.TrackingParameters(1).MaxValues = [.1 .1 .1];
%             obj.TrackingParameters(1).DwellTime = .01;
        end
            
            
        function [data] = performScan(obj,handles,bTracking)
            %handles         gui handles structure for ImageScan figure
            obj.externalStop = false;

            if bTracking == false;
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
                        while (obj.externalStop == false) && (obj.isScanDone() == false)
                            obj.readCounterBuffer(handles);
                            obj.readAnalogBuffer(handles);
                            if bTracking == false % tracking is internal, produces no output
                                obj.updateImage(handles);
                                if obj.bAnalogScan
                                    obj.updateAnalogImage(handles);
                                end
                                obj.updatePositions(handles);
                            end
                            drawnow();%refresh image and flush event queue with stopButton callback
                            pause(0.1);%seconds
                        end
                        % get whatever is left in the buffer once the DAQ
                        % says it's done.
                        obj.readCounterBuffer(handles);
                        if obj.bAnalogScan
                            obj.readAnalogBuffer(handles);
                        end
                        if bTracking == false
                            obj.updateImage(handles);
                            if obj.bAnalogScan
                               obj.updateAnalogImage(handles);
                               %obj.plotPlaneFitAnalogImage(handles); % plot corrected plane image
                            end
                        end
                        
                        if obj.bKeepAllData == true
                            if obj.dimB ~= 0 %insert current data slice
                                obj.cubeData(:,:,iC) = transpose(obj.imageData);
                            else %1D scan
                                obj.cubeData = obj.scanData;
                            end
                        end
                        obj.lastCounterData = obj.counterData;% save to use later
                        if obj.bAnalogScan
                            obj.lastAnalogData = obj.analogData;
                        end
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
            if bTracking == false
                obj.AutomaticSaveScan(handles);
                
            end
        end
        
        function AutomaticSaveScan(obj,handles)
            
           % imageToSave = uint16(obj.imageData);
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
            
            if obj.bAnalogScan
                imageToSaveA = obj.analogImageData; 
                imageInfo2 = obj.scanImageInfo(handles,false, false); % last argument is bTracking
                if isempty(imageInfo2) == true
                    return
                end
                [apart, bpart, ext] = fileparts(imageInfo2.file);
                apart=[apart, '\'];
                bpart=[bpart, 'ai'];
                imageInfo2.file = [apart,bpart,ext];
                switch ext
                    case '.txt'
                        fid = fopen(imageInfo2.file, 'wt');
                        fprintf(fid, imageInfo2.description);
                        fprintf(fid, '\n\n');
                        fclose(fid);
                        dlmwrite(imageInfo2.file, imageToSaveA, '-append', 'delimiter', '\t');
                end
            end
            obj.bAnalogScan=false; % turn to false in any case
        end
        
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
                %store voltage Tuples where Row# gives A position, Col#
                %gives B
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
 
       
        function updateRunningCount(obj,handles)
            lastSample = 0;
            if obj.indexCounterData > 1 && obj.indexCounterData < length(obj.counterData)
                lastSample=obj.counterData(obj.indexCounterData);
                if mod(obj.indexCVoltages,2) == 1
                    lastSample = lastSample - obj.counterData(obj.indexCounterData-1);
                else
                    lastSample = lastSample - obj.counterData(obj.indexCounterData+1);
                end
            end
            lastSample = abs(lastSample) /(1000*obj.currentScanParameters.DwellTime);
            set(handles.editRunningCount,'String',num2str(lastSample));
            handles.CursorControl.addCountToHistory(handles,lastSample);
        end
        
        function updatePositions(obj,handles)%%%generalize and fix
                mpvz = zeros(1,3);
                mpvz(1) = obj.ScanParameters(1).micronsPerVoltX;
                mpvz(2) = obj.ScanParameters(1).micronsPerVoltY;
                mpvz(3) = obj.ScanParameters(1).micronsPerVoltZ;
            if obj.indexCounterData >= 1 && obj.indexCounterData <= size(obj.currentVoltageTuples, 1)
%                 positions = obj.currentVoltageTuples(obj.indexCounterData,:);
%                 strA = sprintf('%.2f',positions(1));
%                 switch obj.dimA
%                     case DAQManager.X
%                         set(handles.editPositionX,'String',strA);
%                     case DAQManager.Y
%                         set(handles.editPositionY,'String',strA);
%                     case DAQManager.Z
%                         set(handles.editPositionZ,'String',strA);
%                 end
%                 if obj.dimB ~= 0
%                     strB = sprintf('%.2f',positions(2));
%                     switch obj.dimB
%                         case DAQManager.Y
%                             set(handles.editPositionY,'String',strB);
%                         case DAQManager.Z
%                             set(handles.editPositionZ,'String',strB);
%                     end
%                 end
                if obj.dimC ~= 0
                    positionC = obj.CVoltages(obj.indexCVoltages);
                    strC = sprintf('%.2f',positionC*mpvz(3));
                    set(handles.editPositionZ,'String',strC); 
                end
            end
        end
        
        function initAOMRepetitionRate(obj,handles,bStart)
            
            % bStart=1: set the desired repetition rate for the scan
            % bStart=0: this call will just set AOM bit1=on for the end of
            % the measurement if using no inverter board, or stop pulse simply 
            %if using inverter board
            if bStart
                
                % first get the desired number of long delay segmetns n for sequence:
                %0 14680064 7 n 500
                %1 14680065 6 n 500
                rate_khz = str2double(get(handles.AOMfreq_kHz,'String'));
                if rate_khz ~= 0 % don't use the AOM sequence in the 0 case
                    half_period_ns = 0.5*10^6/(rate_khz);
                    longDelayMultiplier = half_period_ns/500;
                    
                    % load the instructions into Matlab cell, including
                    % strings for the durations and insutrction-specific
                    % parameters, as in EsrPulsedSweep.m
                    tempCell = handles.PulseInterpreter.loadESRPulse([handles.configS.sequenceFolder 'bit1_pulse_halfperiod_n.txt']);
                    numInstructions=3;
                    numBits=1;
                    tempStrCell = '';
                    tempStr='';
                    pulseNum = zeros(numInstructions,5); % numerical-only form of the instructions
                    for k=1:numInstructions
                        % all instructions are already numeric but the
                        % multiplier. 'eval' allows for operations as well
                        % as the single variable, otherwise
                        % eval->str2double is equivalent
                        pulseNum(k,1)=tempCell{1,1}(k);
                        pulseNum(k,2)=tempCell{1,2}(k);
                        pulseNum(k,3)=tempCell{1,3}(k);
                        tempStrCell = (regexprep( tempCell{1,4}(k),'n',num2str(longDelayMultiplier) ));
                        tempStr=tempStrCell;
                        pulseNum(k,4)=str2double(tempStr);
                        tempStrCell = tempCell{1,5}(k);
                        tempStr = tempStrCell{1};
                        pulseNum(k,5)=str2double(tempStr);
                    end
                    
                    %pulseNum
                    handles.PulseInterpreter.setCurrentPulse(pulseNum);
                    handles.PulseInterpreter.loadToPulseblaster(); 
                    handles.PulseInterpreter.runPulse();
                end
            else
                % end of the measurement, go back to aOM always on
                handles.PulseInterpreter.stopPulse();
                handles.PulseInterpreter.setCurrentPulse([handles.configS.sequenceFolder 'bit1_on.txt']);
                handles.PulseInterpreter.loadToPulseblaster();
                if handles.configS.bHaveInverterBoard == 0
                    % no inverter board, so start the laser on
                    handles.PulseInterpreter.runPulse();
                end
            end
        end
        
        function initializeScan(obj,handles)
            %handles graphics handle for ImageScan figure
            
            %save the current parameters in case the user changes the
            %settings during the scan
            obj.currentScanParameters = obj.ScanParameters(1);
            scan = obj.currentScanParameters;%abbreviate for use later
            
            obj.imageSaveCounter = obj.imageSaveCounter+1;
            if obj.imageSaveCounter >9999
               obj.imageSaveCounter = 0; 
            end
            padded0Str = sprintf('%04d', obj.imageSaveCounter); % pad 4 zeros
            set(handles.inputSaveImageFileNum,'String', padded0Str);

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
            obj.lastScanParameters = ConfocalScanParameters(handles.configS);
            obj.lastScanParameters.ImportScan(obj.currentScanParameters);%save for next time
            
            if NEnabledDims > 1
                obj.imageData = zeros(Nb,Na);
                obj.analogImageData = zeros(Nb,Na);
            else
                obj.scanData = ones(Na); 
            end
            
            if obj.bKeepAllData == true
                obj.cubeData = zeros(Na,Nb,Nc);
            end

            %set up image display
            set(handles.ImageScan,'CurrentAxes',handles.confocalAxes);
            %do not change colormap scaling when new data is put in
            set(handles.confocalAxes,'CLimMode','manual');
            if NEnabledDims > 1
                % 9-17-12, 9-18-12: the scan.Min/MaxValues are already in
                % microns here, so no need to convert.
            	obj.hImage = imagesc([scan.MinValues(obj.dimA),scan.MaxValues(obj.dimA)],...
	        		[scan.MinValues(obj.dimB),scan.MaxValues(obj.dimB)],...
            	obj.imageData,caxis(handles.confocalAxes));
            	set(handles.confocalAxes,'YDir','normal');
            	colorbar('peer',handles.confocalAxes);
                

                xlabel(handles.confocalAxes,[DAQManager.strDims(obj.dimA) ' (µm)']);
                ylabel(handles.confocalAxes,[DAQManager.strDims(obj.dimB) ' (µm)']);
            
                %added 01/14/15 for AFM analog input readout voltages
                
                if get(handles.checkbox_analogInputScan,'Value')
                    obj.bAnalogScan=true;
                    figAI = figure(obj.figAnalogScan);
                    clf(figAI);
                    obj.axesAnalog=axes;
                    
                    xlabel(obj.axesAnalog,'X (um)');
                    ylabel(obj.axesAnalog,'Y (um)');
                    title(obj.axesAnalog,'Analog Input during laser scan');
                    obj.aImage = imagesc([scan.MinValues(obj.dimA),scan.MaxValues(obj.dimA)],...
                        [scan.MinValues(obj.dimB),scan.MaxValues(obj.dimB)],...
                        obj.analogImageData,'Parent',obj.axesAnalog);
                    
                    obj.analogData = zeros(obj.currentNSamples-1,1);
                    obj.initAOMRepetitionRate(handles,1);
                end
            else
                % 9-17-12, 9-18-12 - here the plotting has been done with
                % the obj.AVoltages, which I have as an actual voltage
                % (volts) still, so need ot convert such that we are
                % plotting the 1D scan against microns.
                mpv1D = zeros(1,3);
                mpv1D(1) = obj.ScanParameters(1).micronsPerVoltX;
                mpv1D(2) = obj.ScanParameters(1).micronsPerVoltY;
                mpv1D(3) = obj.ScanParameters(1).micronsPerVoltZ;
                
                obj.hPlot = plot(handles.axesCountHistory,obj.AVoltages*mpv1D(obj.dimA),obj.scanData,'red');
%                 xlabel(handles.axesCountHistory,[DAQManager.strDims(obj.dimA) ' (volts)']);
                xlabel(handles.axesCountHistory,[DAQManager.strDims(obj.dimA) ' (µm)']);
            end

        end %initializeScan
        
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
            
            %dimension X can only be assigned to A, since it is highest
            %priority
            %dimension Y can be A (if X is disabled) or B
            %dimension Z can be A (X,Y disabled), B (X xor Y disabled), or
            %C (X,Y enabled)
        end
        
        function initializeVoltages(obj,handles)
            scan = obj.currentScanParameters;%abbreviate for use later

            %create a list of enabled dimension indices
            enabledDims = find(obj.currentScanParameters.bEnable==1);
            
            NEnabledDims = length(enabledDims);%the number of dimensions of the scan            

            %9-17-12, 9-18-12, added microns/volts conversion
            mpv = zeros(1,3);
            mpv(1) = obj.ScanParameters(1).micronsPerVoltX;
            mpv(2) = obj.ScanParameters(1).micronsPerVoltY;
            mpv(3) = obj.ScanParameters(1).micronsPerVoltZ;
            vpm = zeros(1,3);
            vpm(1) = obj.ScanParameters(1).voltsPerMicronX;
            vpm(2) = obj.ScanParameters(1).voltsPerMicronY;
            vpm(3) = obj.ScanParameters(1).voltsPerMicronZ;
            
            %if using the zoombox to zoom 2D or 3D, set the A and B (x and y on
            %graph) limits to the currently displayed limits
            if get(handles.checkUseZoomboxLimits, 'Value') ==  true ...
                    && NEnabledDims > 1 ...
                    && isempty(obj.lastScanParameters) == false ...
                    && all(scan.bEnable == obj.lastScanParameters.bEnable)
                xlim = sort(get(handles.confocalAxes, 'XLim'));
                ylim = sort(get(handles.confocalAxes, 'YLim'));
                if xlim(1) < obj.DAQ.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA)
                    xlim(1) = obj.DAQ.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA);
                end
                if xlim(2) > obj.DAQ.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA)
                    xlim(2) = obj.DAQ.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA);
                end
                if ylim(1) < obj.DAQ.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimB)
                    ylim(1) = obj.DAQ.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimA);
                end
                if ylim(2) > obj.DAQ.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB)
                    ylim(2) = obj.DAQ.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB);
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
            if scan.bEnable(DAQManager.X) == true
                Vx = linspace(scan.MinValues(DAQManager.X),scan.MaxValues(DAQManager.X),scan.NPoints(DAQManager.X));
                Vx = Vx + scan.OffsetValues(DAQManager.X); %add offset for calibrated center
                obj.XVoltages = Vx*vpm(DAQManager.X);
            else
                obj.XVoltages = [];
            end
            if scan.bEnable(DAQManager.Y) == true
                Vy = linspace(scan.MinValues(DAQManager.Y),scan.MaxValues(DAQManager.Y),scan.NPoints(DAQManager.Y));
                Vy = Vy + scan.OffsetValues(DAQManager.Y);
                obj.YVoltages = Vy*vpm(DAQManager.Y);
            else
                obj.YVoltages = [];
            end
            if scan.bEnable(DAQManager.Z) == true
                Vz = linspace(scan.MinValues(DAQManager.Z),scan.MaxValues(DAQManager.Z),scan.NPoints(DAQManager.Z));
                Vz = Vz + scan.OffsetValues(DAQManager.Z);
                obj.ZVoltages = Vz*vpm(DAQManager.Z);  
            else
                obj.ZVoltages = [];
            end

            %now match X,Y,Z voltages with A,B,C voltages
            % 9-17-12, 9-18-12  A,B,C voltages are also in volts now as the
            % above are in volts
            % set the first voltage...
            switch enabledDims(1)
                case DAQManager.X
                    obj.AVoltages = obj.XVoltages;
                case DAQManager.Y
                    obj.AVoltages = obj.YVoltages;
                case DAQManager.Z
                    obj.AVoltages = obj.ZVoltages;
            end
            % set the second voltage if 2D, 3D....
            if length(enabledDims) > 1
                switch enabledDims(2)
                    case DAQManager.Y
                        obj.BVoltages = obj.YVoltages;
                    case DAQManager.Z
                        obj.BVoltages = obj.ZVoltages;
                end
            end
            % set the third voltage if 3D, always z...
            if NEnabledDims > 2
                obj.CVoltages = obj.ZVoltages;
            end

        end
        
        function updateImage(obj,handles)
            %image(obj.imageData);
            if obj.dimB ~= 0
                set(obj.hImage,'CData',obj.imageData);
                set(handles.ImageScan,'CurrentAxes',handles.confocalAxes);
                colorbar('peer',handles.confocalAxes);
                axis(handles.confocalAxes, 'equal');
                if get(handles.checkboxAutoColorScale,'Value') == true
                     caxis(handles.confocalAxes, 'auto');
                end   
            else
                set(obj.hPlot,'YData',obj.scanData);
            end
            
        end
        
        function updateAnalogImage(obj,handles)
            if obj.dimB ~=0 % should always be the case since we want 2D scans
                set(obj.aImage,'CData',obj.analogImageData);
                %caxis(obj.axesAnalog, 'auto');
                set(obj.axesAnalog, 'YDir', 'normal');
                xlabel(obj.axesAnalog,'X (um)');
                ylabel(obj.axesAnalog,'Y (um)');
                title(obj.axesAnalog,'Analog Input during laser scan');
            end
        end
        
        function plotPlaneFitAnalogImage(obj,handles)
            figure(obj.figAnalogScan);
           scan = obj.currentScanParameters;
            obj.axesAnalog = subplot(2,1,1);
           xmin=scan.MinValues(obj.dimA);
           xmax=scan.MaxValues(obj.dimA);
           ymin=scan.MinValues(obj.dimB);
           ymax=scan.MaxValues(obj.dimB);
           imagesc([xmin,xmax],...
                        [ymin,ymax],...
                        obj.analogImageData,'Parent',obj.axesAnalog);
                    set(obj.axesAnalog, 'YDir', 'normal');
                xlabel(obj.axesAnalog,'X (um)');
                ylabel(obj.axesAnalog,'Y (um)');
                    
            
            [ysz,xsz] = size(obj.analogImageData);
            [xx, yy] = meshgrid(linspace(xmin,xmax,xsz),linspace(ymin,ymax,ysz));
            ss = ones(length(xx(:)),1);
            planeC = [xx(:) yy(:) ss(:)]\obj.analogImageData(:);
            fittedPlane = planeC(1)*xx+planeC(2)*yy+planeC(3);
            correctedAnalogImageData = obj.analogImageData-fittedPlane;
            obj.axesAnalog = subplot(2,1,2);
            imagesc([xmin,xmax],...
                        [ymin,ymax],...
                        correctedAnalogImageData,'Parent',obj.axesAnalog);
                    set(obj.axesAnalog, 'YDir', 'normal');
                xlabel(obj.axesAnalog,'X (um)');
                ylabel(obj.axesAnalog,'Y (um)');
        end
        
        %--- Creates and starts DAQ tasks necessary for a scan
        function startScan(obj,handles)
            dwell = obj.currentScanParameters.DwellTime;%time in seconds 
            %to laser position gathering counter data before moving on
            NSamples = obj.currentNSamples;
           
            if mod(obj.indexCVoltages,2)==0
                obj.indexCounterData = obj.currentNSamples+1;
            else
                obj.indexCounterData = 0;%start filling counter Data array at
            %the beginning
            end
            
             if all(obj.currentScanParameters.bEnable) == true
                obj.DAQ.AnalogOutVoltages(obj.dimC) = obj.ZVoltages(obj.indexCVoltages);
                obj.DAQ.WriteAnalogOutLine(obj.dimC);
                %v = obj.DAQ.AnalogOutVoltages(obj.dimC)
             end
            
             obj.DAQ.ClearAllTasks();
            
           % obj.DAQ.ClearTask('PulseTrain');
           % obj.DAQ.ClearTask('VoltageOut');
            %obj.DAQ.ClearTask('Counter');
            %Create a pulse train to act as a clock to coordinate the
            %position movements and counter measurements
            obj.DAQ.CreateTask('PulseTrain');
            clockFrequency = 1/dwell;
            obj.DAQ.ConfigureClockOut('PulseTrain', DAQManager.CLK1,clockFrequency,obj.dutyCycle);
            
            %set up X position voltages and Y position voltages for the
            %entire scan
            obj.DAQ.CreateTask('VoltageOut');
            obj.generateScanVoltages();%stores values in obj.currentVoltageTuples
            if obj.dimB ~= 0
                VoltageLines = [obj.dimA,obj.dimB];
            else
                VoltageLines = obj.dimA;
            end
            obj.DAQ.ConfigureVoltageOut('VoltageOut',VoltageLines,obj.daqd(:),DAQManager.CLK1);
            %[VoltagesLines selects obj.DAQ.AnalogOutVoltages(obj.dimA) for the A voltage
            %and obj.DAQ.AnalogOutVoltages(obj.dimB) for B for the 2D slice
            %scan
            %obj.currentVoltageTuples(:)
            % Added 01/13/15, analog input for AFM amplitude signal
            % that will sample at the same clockrate as the voltageOut and
            % PL counter
            
            if obj.bAnalogScan
               aiAFMLine = 1;
               obj.DAQ.CreateTask('VoltageIn');
               %---
               obj.DAQ.addAILine('PXI1Slot2/ai17');
               aiAFMLine = 5;
               %---
               obj.DAQ.ConfigureVoltageIn('VoltageIn',aiAFMLine,NSamples,DAQManager.CLK1);
               obj.DAQ.StartTask('VoltageIn');
               
               if mod(obj.indexCVoltages,2)==0
                    obj.indexAnalogData = obj.currentNSamples+1;
               else
                    obj.indexAnalogData = 0;%start filling counter Data array at
                %the beginning
               end
               
               
            end
            
            %set counter to save a sample at each position(voltage pair)
            %visited
            obj.DAQ.CreateTask('Counter');
            obj.DAQ.ConfigureCounterIn('Counter',DAQManager.CTR1,NSamples);
            obj.DAQ.StartTask('Counter');
                  
           
            % wait for tasks to start and for z position to move
           % pause(0.3);
            obj.DAQ.StartTask('VoltageOut');

            % start the sample clock
            if obj.externalStop == false
            %because of pause(.3), we need to check if externally stopped
                obj.DAQ.StartTask('PulseTrain');
            end
        end %startScan
        
        function isScanDone = isScanDone(obj)
            isScanDone = obj.DAQ.IsTaskDone('Counter');
        end
        
        function [analogScanData] = readAnalogBuffer(obj,handles)
           NSamplesAvailable = obj.DAQ.GetAvailableSamples('VoltageIn');
           %testAnalogSamp=NSamplesAvailable
           
           if NSamplesAvailable > 0
               % do not for now allow for any Z scans
               iSample = obj.indexAnalogData + 1;
               jSample = obj.indexAnalogData + NSamplesAvailable;
               increment = 1;
               
               % insert samples
               testAnalogArray1 = obj.DAQ.ReadVoltageIn('VoltageIn',NSamplesAvailable);
               obj.analogData(iSample:increment:jSample) = testAnalogArray1;
               %next new sample will go at index jSample + 1
               obj.indexAnalogData = jSample;
               %turn the analog data array into an image
               analogScanData = obj.formatImageAnalogData();
           else
               analogScanData=[];
           end
        end

        function [scanData] = readCounterBuffer(obj,handles)
            NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
            %testCounterSamp=NSamplesAvailable

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
               
                obj.counterData(iSample:increment:jSample) = obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                %next new sample will go at index jSample + 1
                obj.indexCounterData = jSample;
                %turn the counter data array into an image
                scanData = obj.formatImageData();
            else
                scanData = [];
            end
        end
        
        function [analogScanData] = formatImageAnalogData(obj)
            % both the counter and analog channels will share the property
            % obj.currentNSamples because it just stores Na*NB for the
            % grid size
            analogScanData = obj.analogData;
            %obj.indexAnalogData
            if obj.indexAnalogData > 0 && obj.indexAnalogData <= (obj.currentNSamples-1) % -1 because counter uses an extra
                %if isempty(obj.lastAnalogData) == false
%                     if obj.indexAnalogData > 1 && obj.indexAnalogData < (obj.currentNSamples-1)% -1 because counter uses an extra
%                         if mod(obj.indexCVoltages,2) == 1
%                                 analogScanData(obj.indexAnalogData:end) = obj.lastAnalogData(obj.indexAnalogData:end);
%                         else
%                                 analogScanData(1:obj.indexAnalogData-1) = obj.lastAnalogData(1:obj.indexAnalogData-1);
%                         end
%                         
%                     end
                %else
                    %set all pixels that do not contain data to the minimum data
                    %values
                    if obj.indexAnalogData > 1 && obj.indexAnalogData < (obj.currentNSamples-1)% -1 because counter uses an extra
                        if mod(obj.indexCVoltages,2) == 1
                                minData = mean(analogScanData(1:obj.indexAnalogData-1));
                                analogScanData(obj.indexAnalogData:end) = minData;
                        else
                                minData = mean(analogScanData(obj.indexAnalogData:end));
                                analogScanData(1:obj.indexAnalogData-1) = minData;
                        end
                    end
                    
                %end
                
                %because reshape prioritizes row->col, make X vary with Row# and
                %Y vary with Col#, then transpose
                obj.analogData = analogScanData;
                if obj.dimB ~= 0
                    analogScanData = reshape(analogScanData,obj.currentScanParameters.NPoints(obj.dimA),obj.currentScanParameters.NPoints(obj.dimB));

                    %reverse the X columns since the data was collected in
                    %boustrophedon scanning order.
                    analogScanData(:,2:2:end)=flipud(analogScanData(:,2:2:end));
                    analogScanData = transpose(analogScanData);
                end
                obj.analogImageData = analogScanData;
            else
                analogScanData = [];
            end
                
        end
        
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
 
        function clearTasks(obj,handles)
            %clear scan tasks,  
            obj.DAQ.ClearTask('Counter');
            obj.DAQ.ClearTask('VoltageOut');
            obj.DAQ.ClearTask('PulseTrain'); 
            if obj.bAnalogScan
                obj.DAQ.ClearTask('VoltageIn');
                obj.initAOMRepetitionRate(handles,0); % AOM back to always on
                
            end
        end
        
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
            vpm(1) = obj.ScanParameters(1).voltsPerMicronX;
            vpm(2) = obj.ScanParameters(1).voltsPerMicronY;
            vpm(3) = obj.ScanParameters(1).voltsPerMicronZ;
            
            obj.DAQ.AnalogOutVoltages(obj.dimA) = V(obj.dimA)*vpm(obj.dimA);
            obj.DAQ.WriteAnalogOutLine(obj.dimA);

            if obj.dimB ~= 0
            obj.DAQ.AnalogOutVoltages(obj.dimB) = V(obj.dimB)*vpm(obj.dimB);
            obj.DAQ.WriteAnalogOutLine(obj.dimB);
            end
            
            if obj.dimC ~= 0
                
                obj.DAQ.AnalogOutVoltages(obj.dimC) = V(obj.dimC)*vpm(obj.dimC);
                obj.DAQ.WriteAnalogOutLine(obj.dimC);
            end

%             axis equal
        end
        
        function stopScan(obj)
            obj.externalStop = true;
        end
        
        function delete(obj)
            %clear all NI DAQ tasks
            obj.DAQ.ClearAllTasks();
            %set all output voltages to zero, so we do not continue senting
            %voltages after the program terminates.
            obj.DAQ.AnalogOutVoltages = zeros(length(obj.DAQ.AnalogOutVoltages));
            obj.DAQ.WriteAnalogOutAllLines();
        end
        
        function setParameters(obj, S)
            obj.currentScanParameters = S;
        end
        
        function initializeTrackScan(obj,handles)
            %handles 
            obj.dimA = 1;
            obj.dimB = 2;
            obj.dimC = 3;
            %save the current parameters in case the user changes the
            %settings during the scan
            obj.currentScanParameters = obj.TrackingParameters(1);
            obj.currentScanParameters.OffsetValues = [str2double(get(handles.editPositionX, 'String')) ...
                str2double(get(handles.editPositionY, 'String'))...
                str2double(get(handles.editPositionZ, 'String'))];
            %obj.setParameters(obj.trackingParameters(handles));
            obj.currentNSamples = obj.currentScanParameters.NPoints(obj.dimA)*obj.currentScanParameters.NPoints(obj.dimB) + 1;
            %number of samples = Nx+Ny+Nz+1 because the first counter value
            %won't be at the first desired position, so it will be thrown
            %out, the last sample needs to be at the last desired position
            obj.counterData = 1:obj.currentNSamples;%1:100:100*obj.currentNSamples; %zeros(obj.currentNSamples,1);
            obj.imageData = zeros(obj.currentScanParameters.NPoints(obj.dimB),...
                obj.currentScanParameters.NPoints(obj.dimA));
            
            
            %initialize the userdata variable that the user can change
            %during the scan
            %set(handles.buttonStopScan,'UserData',UserInterrupt);
            
            % 9-17-12, 9-18-12: this V will be in microns. convert before
            % writing to the "obj.XVoltages" and "obj.AVoltages"
            % so again, Vx, Vy, Vz themselves stay in [microns]
            mpv = zeros(1,3);
            mpv(1) = obj.ScanParameters(1).micronsPerVoltX;
            mpv(2) = obj.ScanParameters(1).micronsPerVoltY;
            mpv(3) = obj.ScanParameters(1).micronsPerVoltZ;
            vpm = zeros(1,3);
            vpm(1) = obj.ScanParameters(1).voltsPerMicronX;
            vpm(2) = obj.ScanParameters(1).voltsPerMicronY;
            vpm(3) = obj.ScanParameters(1).voltsPerMicronZ;
            
            scan = obj.currentScanParameters;
            Vx = linspace(scan.MinValues(obj.dimA),scan.MaxValues(obj.dimA),scan.NPoints(obj.dimA));
            Vx = Vx + scan.OffsetValues(DAQManager.X);
            Vx([find(Vx>handles.DAQManager.AnalogOutMaxVoltages(obj.dimA)*mpv(obj.dimA)) find(Vx<handles.DAQManager.AnalogOutMinVoltages(obj.dimA)*mpv(obj.dimA))]) = [];
            obj.XVoltages = Vx*vpm(obj.dimA);
            obj.AVoltages = Vx*vpm(obj.dimA);
            Vy = linspace(scan.MinValues(obj.dimB),scan.MaxValues(obj.dimB),scan.NPoints(obj.dimB));
            Vy([find(Vy>handles.DAQManager.AnalogOutMaxVoltages(obj.dimB)*mpv(obj.dimB)) find(Vy<handles.DAQManager.AnalogOutMinVoltages(obj.dimB)*mpv(obj.dimB))]) = [];
            Vy = Vy + scan.OffsetValues(DAQManager.Y);
            obj.YVoltages = Vy*vpm(obj.dimB);
            obj.BVoltages = Vy*vpm(obj.dimB);
            Vz = linspace(scan.MinValues(obj.dimC), scan.MaxValues(obj.dimC), scan.NPoints(obj.dimC));
            Vz = Vz + scan.OffsetValues(DAQManager.Z);
            Vz([find(Vz>handles.DAQManager.AnalogOutMaxVoltages(obj.dimC)*mpv(obj.dimC)) find(Vz<handles.DAQManager.AnalogOutMinVoltages(obj.dimC)*mpv(obj.dimC))]) = [];
            obj.ZVoltages = Vz*vpm(obj.dimC);
            obj.CVoltages = Vz*vpm(obj.dimC);
            
            % this holds PL data in the cube of voltage points
            obj.cubeData = zeros(length(Vy),length(Vx),length(Vz));
        end
        
        % it is setting the meta data for the image files
        function imageInfo = scanImageInfo(obj,handles,bCurrent,bTracking)
            %defaultPath = 'C:\Users\lab\Documents\code\MATLAB\ImageAquire\data\';%[pwd '\data\'];
            % 11/07/2012 I want to change the default path
            
            myFormattedPathname = get(handles.inputSaveImagePath,'String');
            myFormattedFilePrefix = get(handles.inputSaveImageFilePrefix,'String');
            myFormattedFileNum = get(handles.inputSaveImageFileNum,'String');
            defaultPath = [myFormattedPathname myFormattedFilePrefix myFormattedFileNum];
            if exist(myFormattedPathname,'dir') ==0 %path does not exist?
                mkdir(myFormattedPathname);
            end
            if bTracking == false
                % commented out on 04/18/2013 to make saving automatic
                %[filename fpath ~] = uiputfile({'*.txt', 'Tab-delimited Text File (*.txt)'; '*.csv', 'CSV File (*.csv)';...
                 %   '*.xls', 'Microsoft Excel Spreadsheet (*.xls)'; '*.tiff', 'TIFF Image (*.tiff)';...
                  %  '*.*', 'All Files (*.*)'},'Save Image As...',defaultPath);
                  filename = [myFormattedFilePrefix myFormattedFileNum '.txt'];
                  fpath = myFormattedPathname;
            else
                filename = obj.currentScanParameters.filename;
                fpath = pwd;
            end
            %fpath = defaultPath;
            %filename = get(handles.editFilename,'String');
            if bCurrent
                scan = handles.ScanControl.currentScanParameters;
            else
                scan = handles.ScanControl.lastScanParameters;
            end
            
            bHaveParams = ~isempty(scan);
            if ischar(filename) && bHaveParams
                metadata = get(handles.tableMetaData,'Data');
                description = '';
                for iRow=1:size(metadata,1)
                    description = [description metadata{iRow,1} ': ' metadata{iRow,2} ' $' sprintf('\n')]; %#ok<*AGROW>
                end
                description = [description 'Timestamp: ' datestr(now) ' $' sprintf('\n')];
                description = [description 'DwellTime: ' ...
                    num2str(scan.DwellTime) ' s $' sprintf('\n')];

                strDimension = 'XYZ';
                for iDimension=1:3
                    description = [description 'Min' strDimension(iDimension) ': ' ...
                        num2str(scan.MinValues(iDimension)) ' $' sprintf('\n')];
                    description = [description 'Max' strDimension(iDimension) ': ' ...
                        num2str(scan.MaxValues(iDimension)) ' $' sprintf('\n')];
                    description = [description 'Steps' strDimension(iDimension) ': ' ...
                        num2str(scan.NPoints(iDimension)) ' $' sprintf('\n')];
                    description = [description 'Offset' strDimension(iDimension) ': ' ...
                        num2str(scan.OffsetValues(iDimension)) ' $' sprintf('\n')];
                end

                file = [fpath filename];
                imageInfo.file = file;
                imageInfo.description = description;
            else
                imageInfo = [];
            end
        end
                    
        
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
                    'error with the saving of the scan (Scan control saveScan)'
                end
            end
        end
    end %methods
    
end %classdef
