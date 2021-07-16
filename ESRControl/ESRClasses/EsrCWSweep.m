classdef EsrCWSweep < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       DAQ;
       srs;
       srs2;
       srs3;
%        ESRControlFig;
       pulseBlaster;
       gesr;
       trackParameters;
       imageScanHandles;
       hSweepFitFig1=1123235;
    end
    
    methods
        % ----- initialize the EsrCWSweeps class ----------------------------------------------
        function obj = EsrCWSweep(handles,DAQ,PulseInterpret,SRS,SRS2,SRS3,gESR)
           
           % handle to the AFM GUI called in ImageScan 
           % this is useless though since that GUI is not opened yet = []
%             obj.ESRControlFig = handles.ESRControl;
            obj.imageScanHandles = handles;
           
            obj.DAQ = DAQ; % most likely result, used passed arg
            
            % these devices already have handles, which are passed in
            obj.pulseBlaster = PulseInterpret;
            obj.srs = SRS;
            obj.srs2 = SRS2;
            obj.srs3 = SRS3;
            obj.trackParameters = handles.TrackingParameters;            
            obj.gesr = gESR;
        end
       
        % ------ update ImageScan handles -----------------------------------------------------
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
        
        % ----- perform CW-ESR from ESR_GUI ---------------------------------------------------
        function PerformCWESR(obj,esrGUI)
            obj.gesr.UpdateFileNumber(esrGUI); % update the number attached after the filename
            obj.gesr.UpdateFolder(esrGUI); 
            
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            
            if obj.gesr.CheckAmp(inputAmp,-12) % if amplitude is higher than -12 dBm
                return % interrupt the function
            end
            
            % in case there is any frequency modulation, turn off.
            obj.srs.set_IQ_off();
            
            % get some parameters from string inputs on the ESR GUI
            centerFreq = str2double(get(esrGUI.centerFreq, 'String'));
            numFreqSteps = str2double(get(esrGUI.numFreqSteps, 'String'));
            numAverages = str2double(get(esrGUI.numAverages, 'String'));
            timeStep = str2double(get(esrGUI.timePerFreqStep, 'String'));
            freqdev = str2double(get(esrGUI.CWFreqDeviation, 'String'));
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            trackPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String'));
            obj.gesr.fileWriteFrequency = str2double(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            indDataTraces = [];
            
            % depending on inverter board being installed, set sequence
            if obj.imageScanHandles.configS.bHaveInverterBoard==1 %get(esrGUI.checkboxAOMInverter,'Value')==1
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit3_on.txt']);
            else
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_3_on.txt']);
            end
            obj.pulseBlaster.loadToPulseblaster();
            obj.pulseBlaster.runPulse();
            
            
            % enable the Ntype SRS output, disable the low frequency BNC
            obj.srs.disable_BNC();
            obj.srs.enableNType();
            
            obj.gesr.stopScan = false; % Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
            freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
            obj.gesr.setAmp(esrGUI); %Set the amplitude
            
            set(esrGUI.numCompleted,'String', num2str(0));
            
            % create a list of frequency states in the SRS sig-gen
            obj.srs.create_list(freqValues);
            
            %Initialize the DAQ to collect data
            obj.gesr.NsamplesAcquired = 0;
            averageYData = zeros(1,length(freqValues));
            averageYErrorBars = zeros(1,length(freqValues));
            %Create a pulse train to act as a clock to coordinate the
            %counter measurements
            obj.DAQ.CreateTask('RunningPulseTrain');
            clockFrequency = 1/timeStep;
            clockFrequency = clockFrequency*(10^6);
            clockLine = 1;
            obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.gesr.dutyCycle);
            
            %set counter to save a sample at each position(voltage pair)
            %visited
            obj.DAQ.CreateTask('RunningCounter');
            counterLine = 1;
            obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.gesr.NSamples);
            
            for j = 1:numAverages
                obj.gesr.counterData = [];
                flength = length(freqValues);
                
                % wait for tasks to start
                pause(0.1);

                % start the sample clock

                tstep = timeStep*10^-6;
                for i = 1:flength
%                     fprintf(obj.srs, '*TRG');
                    obj.srs.list_trigger();% trigger the list
                    obj.DAQ.StartTask('RunningCounter');
                    obj.DAQ.StartTask('RunningPulseTrain');
                    tic
                    while toc < tstep
                        %This method of waiting is used because it is far
                        %more accurate if nothing is happening in the
                        %background, but also can be interrupted.
                    end
                    %Acquire data from the DAQs
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
                    if NSamplesAvailable > 0 
                        obj.gesr.counterData = [obj.gesr.counterData diff(double(obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)))/tstep];
                    end
                    obj.DAQ.StopTask('RunningCounter');
                    obj.DAQ.StopTask('RunningPulseTrain');
                end
                if obj.gesr.stopScan
                    break
                end
                set(esrGUI.numCompleted,'String', num2str(j));
                
                %Process the data for graphing
                averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(obj.gesr.counterData - averageYData).^2);
                averageYData = averageYData + (obj.gesr.counterData - averageYData)/j;
                
                %Plot the data, multiply by 0.001 for kCounts
                plot(currentAxes, freqValues, obj.gesr.counterData*0.001, '-.bo',...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','b');
                errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, '-.ro', 'LineWidth', 2.0,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','k');

                title(currentAxes, 'Current Scan');
                title(averageAxes, 'Average Scan');
                ylabel(currentAxes, 'PL (kCounts/s)');
                ylabel(averageAxes, 'PL (kCounts/s)');
                xlabel(currentAxes, 'Frequency (MHz)');
                xlabel(averageAxes, 'Frequency (MHz)');
                
                if ( mod(j, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
                    
                    [fid, ~] = obj.gesr.DefineESRDataSavePath(esrGUI,1);
                    fprintf(fid, '%s\t%s\t%s\t%s\n', 'Frequency','currentSweepCountRate','AverageCountRate','Error');
                    fprintf(fid, '%e\t%e\t%e\t%e\n', [freqValues; obj.gesr.counterData; averageYData; averageYErrorBars/j]);
                    fclose(fid);
                    clear fid
                end
                
               % create array of individual data traces for Matlab saving routine
               indDataTraces(j,:) = obj.gesr.counterData*0.001;
                
                pause(0.1); % and pausing a whole second makes the sweep even faster

                %Run tracking once if we are supposed to on this step and
                % this will also reset the DAQ for data taking
                if (mod(j, trackPeriod)==0) && get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
                    %Set ND filter lower for tracking
                   % CurrentPos = obj.imageScanHandles.FilterWheel.FWCtrl.Position;
                   % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles, 2);
                    obj.gesr.RunSingleTrackCWESR(timeStep, obj.imageScanHandles)
                   % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles,CurrentPos);
                    
                end
                
                drawnow();
            end
            
            obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformCWESR')
            clear indDataTraces
            
            %clear the daq
            obj.DAQ.ClearTask('RunningCounter');
            obj.DAQ.ClearTask('RunningPulseTrain');
            
            %Turn off pulse and clear class, Clear out the RF generator
%             obj.pulseBlaster.stopPulse();
%             if obj.imageScanHandles.configS.bHaveInverterBoard==0
%                 % no inverter board so by default have laser back on
%                 obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
%                 obj.pulseBlaster.loadToPulseblaster();
%                 obj.pulseBlaster.runPulse();
%             end
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
            obj.srs.disable_list();
            obj.srs.destroy_list();
            obj.srs.overload_prevent();
%             fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
%             fclose(obj.srs);
            
            % fit the data with the chosen conditions
            if get(esrGUI.checkboxDoAutoFit,'Value') == 1 
                fitCWESR(freqValues, averageYData, inputAmp);   
            end

            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
        end
        
        function PerformDiffCWESR(obj,esrGUI)
            obj.gesr.UpdateFileNumber(esrGUI); % update the number attached after the filename
            obj.gesr.UpdateFolder(esrGUI); 
            
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            if inputAmp > -3
                danger = questdlg('The amplitude is high for a cw esr measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop

                    case 'Run'
                        % continue on  
                end
            end 
            
            % in case there is any frequency modulation, turn off.
%             fclose(obj.srs);
%             fopen(obj.srs);
%             fprintf(obj.srs, 'MODL0');
%             fclose(obj.srs);
            obj.srs.set_IQ_off();
            
            % get some parameters from string inputs on the ESR GUI
            centerFreq = str2double(get(esrGUI.centerFreq, 'String'));
            numFreqSteps = str2double(get(esrGUI.numFreqSteps, 'String'));
            numAverages = str2double(get(esrGUI.numAverages, 'String'));
            timeStep = str2double(get(esrGUI.timePerFreqStep, 'String'));
            freqdev = str2double(get(esrGUI.CWFreqDeviation, 'String'));
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            trackPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String'));
            obj.gesr.fileWriteFrequency = str2double(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
             obj.pulseBlaster.clearPulseblaster();
             obj.pulseBlaster.setCurrentPulse('ESRref_cont100us.txt');
             obj.pulseBlaster.loadToPulseblaster();
             obj.pulseBlaster.runPulse();
            
            
            % enable the Ntype SRS output, disable the low frequency BNC
%             fopen(obj.srs);
%             fprintf(obj.srs, ['ENBL ', '0']);
%             fprintf(obj.srs, ['ENBR ', '1']);
%             fclose(obj.srs);
            obj.srs.enableNType();
            obj.srs.disable_BNC();
            
            obj.gesr.stopScan = false; % Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
            freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
            obj.gesr.setAmp(esrGUI); %Set the amplitude
            
            set(esrGUI.numCompleted,'String', num2str(0));
            
            % create a list of frequency states in the SRS sig-gen
%             fopen(obj.srs);
%             fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
%             fprintf(obj.srs, '*CLS');
%             freqHz = freqValues*(10^6);
%             for i = 1:length(freqHz)
%                    % pre-load each state of the list into the SG384 memory
%                    fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
%             end
%             % enable the list
%             fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
%             
            obj.srs.create_list(freqValues);

            %Initialize the DAQ to collect data
            YData = zeros(1,length(freqValues));
            averageYData = zeros(1,length(freqValues));
            averageYErrorBars = zeros(1,length(freqValues));
            
            obj.DAQ.ClearTask('Counter');
            obj.DAQ.CreateTask('Counter');
            repsPerTau = str2double(get(esrGUI.repsPerTau,'String'));
            NPulseSamples = 2*repsPerTau+1;
            counterLine = 3;
            obj.DAQ.ConfigureCounterUpDownIn('Counter',counterLine,NPulseSamples);
            
            for j = 1:numAverages
                obj.gesr.counterData = zeros(1,NPulseSamples);
                flength = length(freqValues);
                
                for i = 1:flength
%                     fprintf(obj.srs, '*TRG');  
                    obj.srs.list_trigger();% trigger the list
                    obj.DAQ.StartTask('Counter');
                    
                    w = 0;
                    while((obj.DAQ.GetAvailableSamples('Counter') < NPulseSamples) && (w < 1000))
                        pause(0.01);
                        w = w + 1;
                    end

                    %Acquire data from the DAQs
                    obj.gesr.GetCountsUntilBuffersFilled(1);
                    YData(i) = obj.gesr.counterData(end) - obj.gesr.counterData(1);
                    obj.DAQ.StopTask('Counter');
                    
                end
                if obj.gesr.stopScan
                    break
                end
                set(esrGUI.numCompleted,'String', num2str(j));
                
                %Process the data for graphing
                averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(YData - averageYData).^2);
                averageYData = averageYData + (YData - averageYData)/j;
                
                %Plot the data, multiply by 0.001 for kCounts
                plot(currentAxes, freqValues, YData, '-.bo',...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','b');
                errorbar(averageAxes, freqValues, j*averageYData,averageYErrorBars, '-.ro', 'LineWidth', 2.0,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','k');

                title(currentAxes, 'Current Scan');
                title(averageAxes, 'Average Scan');
                ylabel(currentAxes, 'PL (Diff Counts)');
                ylabel(averageAxes, 'PL (Diff Counts)');
                xlabel(currentAxes, 'Frequency (MHz)');
                xlabel(averageAxes, 'Frequency (MHz)');
                
                if ( mod(j, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
                    
                    [fid, ~] = obj.gesr.DefineESRDataSavePath(esrGUI,1);
                    fprintf(fid, '%s\t%s\t%s\t%s\n', 'Frequency','currentSweepCountRate','AverageCountRate','Error');
                    fprintf(fid, '%e\t%e\t%e\t%e\n', [freqValues; YData; averageYData; averageYErrorBars/j]);
                    fclose(fid);
                    clear fid
                end
                
               % create array of individual data traces for Matlab saving routine
               indDataTraces(j,:) = obj.gesr.counterData*0.001;
                
                pause(0.05); % and pausing a whole second makes the sweep even faster
                
                %Run tracking once if we are supposed to on this step and
                % this will also reset the DAQ for data taking
                if (mod(j, trackPeriod)==0) && get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
                    
                    %Set ND filter lower for tracking
                   % CurrentPos = obj.imageScanHandles.FilterWheel.FWCtrl.Position;
                   % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles, 2);
                    obj.gesr.RunSingleTrackCWESR(timeStep, obj.imageScanHandles)
                   % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles,CurrentPos);
                    
                end
            end
            
            obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformDiffCWESR')
            clear indDataTraces
            
            %clear the daq
            obj.DAQ.ClearTask('Counter');
            
            %Turn off pulse and clear class, Clear out the RF generator
            obj.pulseBlaster.stopPulse();
            if obj.imageScanHandles.configS.bHaveInverterBoard==0
                % no inverter board so by default have laser back on
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                obj.pulseBlaster.loadToPulseblaster();
                obj.pulseBlaster.runPulse();
            end
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
%             fclose(obj.srs);
            obj.srs.disable_list();
            obj.srs.destroy_list();
            obj.srs.overload_prevent();
            obj.srs.disableNType();
             
            % fit the data with the chosen conditions
            if get(esrGUI.checkboxDoAutoFit,'Value') == 1
                fitCWESR(freqValues, averageYData);
            end
            
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
        end
        
        % ------- CW-ESR sequence as used from AFM scan software ------------------------------
        function PerformScanCWESR(obj,esrGUI)
            global previousFreqSplitting;
            % make sure data is saved in current date folder
            obj.gesr.UpdateFolder(esrGUI);
            % update the file number to prevent saving over your data
            obj.gesr.UpdateFileNumber(esrGUI);
            
            % get some parameters from string inputs on the ESR GUI
            centerFreq = str2double(get(esrGUI.centerFreq, 'String'));
            numAverages = str2double(get(esrGUI.numAverages, 'String'));
            timeStep = str2double(get(esrGUI.timePerFreqStep, 'String'));
            freqdev = str2double(get(esrGUI.CWFreqDeviation, 'String')); %round(previousFreqSplitting/2)+30;
            numFreqSteps = round(freqdev);
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            trackPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String'));
            obj.gesr.fileWriteFrequency = str2double(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
            obj.gesr.stopScan = false; % Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
            freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
            
            set(esrGUI.numCompleted,'String', num2str(0));
            
            % create a list of frequency states in the SRS sig-gen
%             fclose(obj.srs);
%             fopen(obj.srs);
%             fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
%             fprintf(obj.srs, '*CLS');
%             freqHz = freqValues*(10^6);
%             for i = 1:length(freqHz)
%                    % pre-load each state of the list into the SG384 memory
%                    fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
%             end
%             % enable the list
%             fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
            obj.srs.create_list(freqValues);
            
            
            %Initialize the DAQ to collect data
            obj.gesr.NsamplesAcquired = 0;
            averageYData = zeros(1,length(freqValues));
            averageYErrorBars = zeros(1,length(freqValues));
            %Create a pulse train to act as a clock to coordinate the
            %counter measurements
            obj.DAQ.CreateTask('RunningPulseTrain');
            clockFrequency = 1/timeStep;
            clockFrequency = clockFrequency*(10^6);
            clockLine = 1;
            obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.gesr.dutyCycle);
            
            %set counter to save a sample at each position(voltage pair)
            %visited
            obj.DAQ.CreateTask('RunningCounter');
            counterLine = 1;
            obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.gesr.NSamples);
            pause(0.05);
            
            startingNumAverages = numAverages;
            j=1;
            while (j <= numAverages)
                obj.gesr.counterData = [];
                flength = length(freqValues);
                
                % wait for tasks to start
                

                % start the sample clock

                tstep = timeStep*10^-6;
                for i = 1:flength
%                     fprintf(obj.srs, '*TRG');
                    obj.srs.list_trigger(); % trigger the list
                    obj.DAQ.StartTask('RunningCounter');
                    obj.DAQ.StartTask('RunningPulseTrain');
                    tic
                    while toc < tstep
                        %This method of waiting is used because it is far
                        %more accurate if nothing is happening in the
                        %background, but also can be interrupted.
                    end
                    %Acquire data from the DAQs
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
                    if NSamplesAvailable > 0 
                        obj.gesr.counterData = [obj.gesr.counterData diff(double(obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)))/tstep];
                    end
                    obj.DAQ.StopTask('RunningCounter');
                    obj.DAQ.StopTask('RunningPulseTrain');
                end
                if obj.gesr.stopScan
                    break
                end
                set(esrGUI.numCompleted,'String', num2str(j));
                
                %Process the data for graphing
                averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(obj.gesr.counterData - averageYData).^2);
                averageYData = averageYData + (obj.gesr.counterData - averageYData)/j;
                
                % create array of individual data traces for Matlab saving routine
                indDataTraces(j,:) = obj.gesr.counterData*0.001;
                
                j = j+1;
                if (j==startingNumAverages)
%                     r2 = fitCWESRScan(freqValues, averageYData, 1e4);
%                     if (r2 < 0.7)
%                         numAverages = 2*numAverages;
%                     end
                end
                
            end
%             if (r2 < 0.7)
%                 r2 = fitCWESRScan(freqValues, averageYData, 1e4);
%                 previousFreqSplitting = 80;
%             end
            
            numSweeps = length(indDataTraces);
            %Plot the data, multiply by 0.001 for kCounts
                plot(currentAxes, freqValues, obj.gesr.counterData*0.001, '-.bo',...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','b');
                errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/numSweeps, '-.ro', 'LineWidth', 2.0,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','k');

                title(currentAxes, 'Current Scan');
                title(averageAxes, 'Average Scan');
                ylabel(currentAxes, 'PL (kCounts/s)');
                ylabel(averageAxes, 'PL (kCounts/s)');
                xlabel(currentAxes, 'Frequency (MHz)');
                xlabel(averageAxes, 'Frequency (MHz)');
                
                pause(0.05); % and pausing a whole second makes the sweep even faster
            
            obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformScanCWESR')
            clear indDataTraces
            
            %clear the daq
            obj.DAQ.ClearTask('RunningCounter');
            obj.DAQ.ClearTask('RunningPulseTrain');
            
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fclose(obj.srs);
            obj.srs.disable_list();
            obj.srs.destroy_list();
            obj.srs.overload_prevent();
            
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
        end
        
        % ------ CW-ESR with RF on/off as used from AFM scan software -------------------------
        function PerformScanDiffCWESR(obj,esrGUI)
            obj.gesr.UpdateFileNumber(esrGUI); % update the number attached after the filename
            obj.gesr.UpdateFolder(esrGUI); 
            
            % get some parameters from string inputs on the ESR GUI
            centerFreq = str2double(get(esrGUI.centerFreq, 'String'));
            numFreqSteps = str2double(get(esrGUI.numFreqSteps, 'String'));
            numAverages = str2double(get(esrGUI.numAverages, 'String'));
            timeStep = str2double(get(esrGUI.timePerFreqStep, 'String'));
            freqdev = str2double(get(esrGUI.CWFreqDeviation, 'String'));
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            trackPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String'));
            obj.gesr.fileWriteFrequency = str2double(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
            obj.gesr.stopScan = false; % Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
            freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
            
            set(esrGUI.numCompleted,'String', num2str(0));
            
            % create a list of frequency states in the SRS sig-gen
            fclose(obj.srs);
            fopen(obj.srs);
            fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
            fprintf(obj.srs, '*CLS');
            freqHz = freqValues*(10^6);
            for i = 1:length(freqHz)
                   % pre-load each state of the list into the SG384 memory
                   fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
            end
            % enable the list
            fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
            
            %Initialize the DAQ to collect data
            obj.gesr.NsamplesAcquired = 0;
            %Initialize the DAQ to collect data
            contrast = zeros(1,length(freqValues));
            count_diff = zeros(1,length(freqValues));
            count_total = zeros(1,length(freqValues));
            averageContrast = zeros(1,length(freqValues));
            averageContrastError = zeros(1,length(freqValues));
            
            repsPerTau = str2double(get(esrGUI.repsPerTau,'String'));
            dwellTime = timeStep*(1e-6);
            NPulseSamples = round(dwellTime/(1e-4));
            
            pause(0.05);
            startingNumAverages = numAverages;
            
            for j = 1:numAverages
                
                flength = length(freqValues);
                
                for i = 1:flength
%                     fprintf(obj.srs, '*TRG'); 
                    obj.srs.list_trigger(); % trigger the list
                    pause(0.005)
                    [contrast(i), countDiff(i), countTotal(i)] = get_count_contrast(NPulseSamples);
                    
                end
                
                if obj.gesr.stopScan
                    break
                end
                set(esrGUI.numCompleted,'String', num2str(j));
                
                %Process the data for graphing
                averageContrastError = sqrt(averageContrastError.^2 + ((j-1)/j)*(contrast - averageContrast).^2);
                averageContrast = averageContrast + (contrast - averageContrast)/j;
                
                % create array of individual data traces for Matlab saving routine
                indContrastTraces(j,:) = contrast;
                indCountDiffTraces(j,:) = countDiff;
                indCountTotalTraces(j,:) = countTotal;
                
                if (j==startingNumAverages)
                    r2 = fitCWESRDiffScan(freqValues, averageContrast, 0.05);
                    if (r2 < 0.9)
                        j = 1;
                    end
                end
                
            end
            if (r2 < 0.75)
                r2 = fitCWESRDiffScan(freqValues, averageContrast, 0.05);
            end
            
            %Plot the data, multiply by 0.001 for kCounts
            plot(currentAxes, freqValues, contrast, '-.bo',...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','b');
            errorbar(averageAxes, freqValues, averageContrast, averageContrastError/j, '-.ro', 'LineWidth', 2.0,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor','k');
            
            title(currentAxes, 'Current Scan');
            title(averageAxes, 'Average Scan');
            ylabel(currentAxes, 'RF on/off contrast');
            ylabel(averageAxes, 'RF on/off contrast');
            xlabel(currentAxes, 'Frequency (MHz)');
            xlabel(averageAxes, 'Frequency (MHz)');
    
            pause(0.01); % and pausing a whole second makes the sweep even faster
            
            obj.gesr.saveDiffEsrMatFile(esrGUI,freqValues,averageContrast,averageContrastError,indContrastTraces,indCountDiffTraces,indCountTotalTraces,'PerformScanDiffCWESR')
            clear indDataTraces
            
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fclose(obj.srs);
            obj.srs.disable_list();
            obj.srs.destroy_list();
            obj.srs.overload_prevent();
            
            % fit the data with the chosen conditions
            %             fitCWESR(freqValues, averageYData);
            
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
        end
        
        
%        % -----      --------------------
%         function PerformScanVarWidthCWESR(obj,esrGUI)
%             % make sure data is saved in current date folder
%             obj.gesr.UpdateFolder(esrGUI);
%             % update the file number to prevent saving over your data
%             obj.gesr.UpdateFileNumber(esrGUI);
%             
%            
%             % get some parameters from string inputs on the ESR GUI
%             global ESR_splitting;
%             centerFreq = str2double(get(esrGUI.centerFreq, 'String'));
%             numAverages = str2double(get(esrGUI.numAverages, 'String'));
%             timeStep = str2double(get(esrGUI.timePerFreqStep, 'String'));
%             freqdev = str2double(get(esrGUI.CWFreqDeviation, 'String'))+floor(ESR_splitting/2)
%             numFreqSteps = freqdev;
%             freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
%             currentAxes = esrGUI.axesCurrentSweep;
%             averageAxes = esrGUI.axesNormalized;
%             trackPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String'));
%             obj.gesr.fileWriteFrequency = str2double(get(esrGUI.writeDataFreq,'String'));
%             obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
%             obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
%             obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
%             
%             obj.gesr.stopScan = false; % Stop any scans if they are already running
%             obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
%             freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
%             obj.gesr.setAmp(esrGUI); %Set the amplitude
%             
%             set(esrGUI.numCompleted,'String', num2str(0));
%             
%             % create a list of frequency states in the SRS sig-gen
%             fopen(obj.srs);
%             fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
%             fprintf(obj.srs, '*CLS');
%             freqHz = freqValues*(10^6);
%             for i = 1:length(freqHz)
%                    % pre-load each state of the list into the SG384 memory
%                    fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
%             end
%             % enable the list
%             fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
%             
%             %Initialize the DAQ to collect data
%             obj.gesr.NsamplesAcquired = 0;
%             averageYData = zeros(1,length(freqValues));
%             averageYErrorBars = zeros(1,length(freqValues));
%             %Create a pulse train to act as a clock to coordinate the
%             %counter measurements
%             obj.DAQ.CreateTask('RunningPulseTrain');
%             clockFrequency = 1/timeStep;
%             clockFrequency = clockFrequency*(10^6);
%             clockLine = 1;
%             obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.gesr.dutyCycle);
%             
%             %set counter to save a sample at each position(voltage pair)
%             %visited
%             obj.DAQ.CreateTask('RunningCounter');
%             counterLine = 1;
%             obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.gesr.NSamples);
%             pause(0.1);
%             for j = 1:numAverages
%                 obj.gesr.counterData = [];
%                 flength = length(freqValues);
%                 
%                 % wait for tasks to start
%                 
% 
%                 % start the sample clock
% 
%                 tstep = timeStep*10^-6;
%                 for i = 1:flength
%                     fprintf(obj.srs, '*TRG');                 % trigger the list
%                     obj.DAQ.StartTask('RunningCounter');
%                     obj.DAQ.StartTask('RunningPulseTrain');
%                     tic
%                     while toc < tstep
%                         %This method of waiting is used because it is far
%                         %more accurate if nothing is happening in the
%                         %background, but also can be interrupted.
%                     end
%                     %Acquire data from the DAQs
%                     NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
%                     if NSamplesAvailable > 0 
%                         obj.gesr.counterData = [obj.gesr.counterData diff(double(obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)))/tstep];
%                     end
%                     obj.DAQ.StopTask('RunningCounter');
%                     obj.DAQ.StopTask('RunningPulseTrain');
%                 end
%                 if obj.gesr.stopScan
%                     break
%                 end
%                 set(esrGUI.numCompleted,'String', num2str(j));
%                 
%                 %Process the data for graphing
%                 averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(obj.gesr.counterData - averageYData).^2);
%                 averageYData = averageYData + (obj.gesr.counterData - averageYData)/j;
%                 
%                 % create array of individual data traces for Matlab saving routine
%                 indDataTraces(j,:) = obj.gesr.counterData*0.001;
%                 
%             end
%             
%             %Plot the data, multiply by 0.001 for kCounts
%                 plot(currentAxes, freqValues, obj.gesr.counterData*0.001, '-.bo',...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','b');
%                 errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, '-.ro', 'LineWidth', 2.0,...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','k');
% 
%                 title(currentAxes, 'Current Scan');
%                 title(averageAxes, 'Average Scan');
%                 ylabel(currentAxes, 'PL (kCounts/s)');
%                 ylabel(averageAxes, 'PL (kCounts/s)');
%                 xlabel(currentAxes, 'Frequency (MHz)');
%                 xlabel(averageAxes, 'Frequency (MHz)');
%                 
%                 if ( mod(j, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
%                     
%                     [fid, ~] = obj.gesr.DefineESRDataSavePath(esrGUI,1);
%                     fprintf(fid, '%s\t%s\t%s\t%s\n', 'Frequency','currentSweepCountRate','AverageCountRate','Error');
%                     fprintf(fid, '%e\t%e\t%e\t%e\n', [freqValues; obj.gesr.counterData; averageYData; averageYErrorBars/j]);
%                     fclose(fid);
%                     clear fid
%                 end
%                 
%                 pause(0.1); % and pausing a whole second makes the sweep even faster
%                 
%                 %Run tracking once if we are supposed to on this step and
%                 % this will also reset the DAQ for data taking
%                 if (mod(j, trackPeriod)==0) && get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
%                     
%                     %Set ND filter lower for tracking
%                    % CurrentPos = obj.imageScanHandles.FilterWheel.FWCtrl.Position;
%                    % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles, 2);
%                     obj.gesr.RunSingleTrackCWESR(timeStep, obj.imageScanHandles)
%                    % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles,CurrentPos);
%                     
%                 end
%             
%             obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformScanVarWidthCWESR')
%             clear indDataTraces
%             
%             %clear the daq
%             obj.DAQ.ClearTask('RunningCounter');
%             obj.DAQ.ClearTask('RunningPulseTrain');
%             
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fclose(obj.srs);
%             
%             % fit the data with the chosen conditions
%             fitCWESR(freqValues, averageYData);
%             
%             obj.gesr.EnableGui(esrGUI);
%             obj.gesr.stopScan = false;
%         end
%         
%         function PerformScanPart1CWESR(obj,esrGUI)
%             % make sure data is saved in current date folder
%             obj.gesr.UpdateFolder(esrGUI);
%             % update the file number to prevent saving over your data
%             obj.gesr.UpdateFileNumber(esrGUI);
%             
%             %safety check
% %             inputAmp = str2double(get(esrGUI.amplitude,'String'));
% %             if inputAmp > -3
% %                 danger = questdlg('The amplitude is high for a cw esr measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
% %                 switch(danger)
% %                     case 'Abort'
% %                         return
% %                         % exit the perform sequence if user chooses to stop
% % 
% %                     case 'Run'
% %                         % continue on  
% %                 end
% %             end 
%             
%             % get some parameters from string inputs on the ESR GUI
%             global c1_freq;
%             global c1_freq_start;
%             numFreqSteps = str2num(get(esrGUI.numFreqSteps, 'String'));
%             numAverages = str2num(get(esrGUI.numAverages, 'String'));
%             timeStep = str2num(get(esrGUI.timePerFreqStep, 'String'));
%             freqdev = str2num(get(esrGUI.CWFreqDeviation, 'String'));
%             freqSweepRange1 = c1_freq + freqdev*[-1 1]; % set freq range
%             if freqSweepRange1(1) < 2870
%                 freqSweepRange1(1) = 2870;
%             end
%             currentAxes = esrGUI.axesCurrentSweep;
%             averageAxes = esrGUI.axesNormalized;
%             trackPeriod = str2num(get(esrGUI.cwTrackingPeriod,'String'));
%             obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
%             obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
%             obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
%             obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
%             
%             obj.gesr.stopScan = false; % Stop any scans if they are already running
%             obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
%             freqValues = linspace(freqSweepRange1(1), freqSweepRange1(2), numFreqSteps);
%             obj.gesr.setAmp(esrGUI); %Set the amplitude
%             
%             set(esrGUI.numCompleted,'String', num2str(0));
%             
%             % create a list of frequency states in the SRS sig-gen
%             fopen(obj.srs);
%             fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
%             fprintf(obj.srs, '*CLS');
%             freqHz = freqValues*(10^6);
%             for i = 1:length(freqHz)
%                    % pre-load each state of the list into the SG384 memory
%                    fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
%             end
%             % enable the list
%             fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
%             
%             %Initialize the DAQ to collect data
%             obj.gesr.NsamplesAcquired = 0;
%             averageYData = zeros(1,length(freqValues));
%             averageYErrorBars = zeros(1,length(freqValues));
%             %Create a pulse train to act as a clock to coordinate the
%             %counter measurements
%             obj.DAQ.CreateTask('RunningPulseTrain');
%             clockFrequency = 1/timeStep;
%             clockFrequency = clockFrequency*(10^6);
%             clockLine = 1;
%             obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.gesr.dutyCycle);
%             
%             %set counter to save a sample at each position(voltage pair)
%             %visited
%             obj.DAQ.CreateTask('RunningCounter');
%             counterLine = 1;
%             obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.gesr.NSamples);
%             
%             for j = 1:numAverages
%                 obj.gesr.counterData = [];
%                 flength = length(freqValues);
%                 
%                 % wait for tasks to start
%                 pause(0.1);
% 
%                 % start the sample clock
% 
%                 tstep = timeStep*10^-6;
%                 for i = 1:flength
%                     fprintf(obj.srs, '*TRG');                 % trigger the list
%                     obj.DAQ.StartTask('RunningCounter');
%                     obj.DAQ.StartTask('RunningPulseTrain');
%                     tic
%                     while toc < tstep
%                         %This method of waiting is used because it is far
%                         %more accurate if nothing is happening in the
%                         %background, but also can be interrupted.
%                     end
%                     %Acquire data from the DAQs
%                     NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
%                     if NSamplesAvailable > 0 
%                         obj.gesr.counterData = [obj.gesr.counterData diff(double(obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)))/tstep];
%                     end
%                     obj.DAQ.StopTask('RunningCounter');
%                     obj.DAQ.StopTask('RunningPulseTrain');
%                 end
%                 if obj.gesr.stopScan
%                     break
%                 end
%                 set(esrGUI.numCompleted,'String', num2str(j));
%                 
%                 %Process the data for graphing
%                 averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(obj.gesr.counterData - averageYData).^2);
%                 averageYData = averageYData + (obj.gesr.counterData - averageYData)/j;
%                 
%                 %Plot the data, multiply by 0.001 for kCounts
%                 plot(currentAxes, freqValues, obj.gesr.counterData*0.001, '-.bo',...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','b');
%                 errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, '-.ro', 'LineWidth', 2.0,...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','k');
% 
%                 title(currentAxes, 'Current Scan');
%                 title(averageAxes, 'Average Scan');
%                 ylabel(currentAxes, 'PL (kCounts/s)');
%                 ylabel(averageAxes, 'PL (kCounts/s)');
%                 xlabel(currentAxes, 'Frequency (MHz)');
%                 xlabel(averageAxes, 'Frequency (MHz)');
%                 
%                 if ( mod(j, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
%                     
%                     [fid, ~] = obj.gesr.DefineESRDataSavePath(esrGUI,1);
%                     fprintf(fid, '%s\t%s\t%s\t%s\n', 'Frequency','currentSweepCountRate','AverageCountRate','Error');
%                     fprintf(fid, '%e\t%e\t%e\t%e\n', [freqValues; obj.gesr.counterData; averageYData; averageYErrorBars/j]);
%                     fclose(fid);
%                     clear fid
%                 end
%                 
%                 % create array of individual data traces for Matlab saving routine
%                 indDataTraces(j,:) = obj.gesr.counterData*0.001;
%                 
%                 pause(0.1); % and pausing a whole second makes the sweep even faster
%                 
%                 %Run tracking once if we are supposed to on this step and
%                 % this will also reset the DAQ for data taking
%                 if (mod(j, trackPeriod)==0) && get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
%                     
%                     %Set ND filter lower for tracking
%                    % CurrentPos = obj.imageScanHandles.FilterWheel.FWCtrl.Position;
%                    % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles, 2);
%                     obj.gesr.RunSingleTrackCWESR(timeStep, obj.imageScanHandles)
%                    % obj.imageScanHandles.FilterWheel.goToFilter(obj.imageScanHandles,CurrentPos);
%                     
%                 end
%             end
%             
%             obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformScanPart1CWESR')
%             clear indDataTraces
%             
%             %clear the daq
%             obj.DAQ.ClearTask('RunningCounter');
%             obj.DAQ.ClearTask('RunningPulseTrain');
%             
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fclose(obj.srs);
%             
%              global ESR_splitting;
%             % fit the data with the chosen conditions
%             if get(esrGUI.checkboxDoAutoFit,'Value') == 1
%                % figSweepFit = figure(obj.hSweepFitFig1);
%                % clf(figSweepFit);
%                 
%                 % use the peakfit function in the ImageScan directory
%                 % I took out the call to "figure" I had put in "peakfit.m"
%                 % so now it will use the current figure, figSweepFit
%                 dataToFit1 = averageYData(1:numFreqSteps)';
%                 dataToFit1 = max(dataToFit1)-dataToFit1;
%                 
%                 [peaks] = peakfinder(dataToFit1, 3000);
%                 peak_list = [dataToFit1(peaks) peaks];
%                 peak_list = flipud(sortrows(peak_list,1));
%                 
% %                 [peaks] = peakfinder(dataToFit1, 3000);
% %                 peak_list = [dataToFit1(peaks) peaks];
% %                 peak_list = flipud(sortrows(peak_list,1));
% %                 c1_freq_guess = c1_freq;
% %                 
% %                 if (length(peaks)>=1)
% %                     c1_freq_guess = freqValues(peak_list(1,2));
% %                 end
% 
%                 
% %                 dataToFit2 = averageYData(numFreqSteps+1:2*numFreqSteps)';
% %                 dataToFit2 = max(dataToFit2)-dataToFit2;
%                     peakguess = c1_freq;
%                     if length(peak_list) >=1
%                         peakguess = freqValues(peak_list(1,2));
%                     end
%                     figure(6000);
%                     [CWFitResults,~] = peakfit([freqValues' dataToFit1],0,0,1,1,0,1,[peakguess 10],1);
% %                         peakfit([freqValues' dataToFit1],peakguess,50);
%                     
%                     
%                     if abs(CWFitResults(1,2)-c1_freq)<70
%                         c1_freq = CWFitResults(1,2);
%                     end
%                     
%                     
% %                     figure(6001);
% %                     [CWFitResults,~]=...
% %                         peakfit([freqValues(numFreqSteps+1:2*numFreqSteps)' dataToFit2]);
% %                     if abs(CWFitResults(1,2)-c2_freq)<60
% %                         c2_freq = CWFitResults(1,2)
% %                     end
%                     
%                     if (c1_freq < 2865) || (c1_freq >3300)
%                         c1_freq = c1_freq_start
%                     end
% %                     if (c2_freq < 2870) || (c2_freq >3100)
% %                         c2_freq = c2_freq_start
% %                     end
%                     % for a two peak fit, the center frequency results are
%                     % given by CWFitResults(1,2) and CWFitResults(2,2)
%                     
% %                     ESR_splitting = c2_freq-c1_freq;
%                         ESR_splitting = 2870-c1_freq;
% 
% %                     set(esrGUI.curveFreqM,'String',num2str(fms(1)));
% %                     set(esrGUI.curveFreqP,'String',num2str(fms(2)));
%                     %set(esrGUI.curveB0,'String',num2str(esrB0));
%                    % set(esrGUI.curveTheta,'String',num2str(esrTheta));
%                 else
%                      ESR_splitting = 0;
%                 
%             end
%             
%             ESR_splitting
%             obj.gesr.EnableGui(esrGUI);
%             obj.gesr.stopScan = false;
%         end
%         
%          function PerformScanPart2CWESR(obj,esrGUI)
%             % make sure data is saved in current date folder
%             obj.gesr.UpdateFolder(esrGUI);
%             % update the file number to prevent saving over your data
%             obj.gesr.UpdateFileNumber(esrGUI);
% 
%             global c1_freq;
%             global c2_freq;
%             global c1_freq_start;
%             global c2_freq_start;
%             
%             numFreqSteps = str2num(get(esrGUI.numFreqSteps, 'String'));
%             numAverages = str2num(get(esrGUI.numAverages, 'String'));
%             timeStep = str2num(get(esrGUI.timePerFreqStep, 'String'));
%             freqdev = str2num(get(esrGUI.CWFreqDeviation, 'String'));
%             freqSweepRange1 = c1_freq + freqdev*[-1 1]; % set freq range
%             freqSweepRange2 = c2_freq + freqdev*[-1 1];
%             if freqSweepRange1(2) > 2880
%                 freqSweepRange1(2) = 2880;
%             end
%             if freqSweepRange2(1) < 2870
%                 freqSweepRange2(1) = 2870;
%             end
%             currentAxes = esrGUI.axesCurrentSweep;
%             averageAxes = esrGUI.axesNormalized;
%             trackPeriod = str2num(get(esrGUI.cwTrackingPeriod,'String'));
%             obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
%             obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
%             obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
%             obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
%             
%             obj.gesr.stopScan = false; % Stop any scans if they are already running
%             obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
%             freqValues1 = linspace(freqSweepRange1(1), freqSweepRange1(2), numFreqSteps);
%             freqValues2 = linspace(freqSweepRange2(1), freqSweepRange2(2), numFreqSteps);
%             freqValues = cat(2,freqValues1,freqValues2);
%             
%             
% %             freqValues = linspace(freqSweepRange1(1), freqSweepRange1(2), numFreqSteps);
%             obj.gesr.setAmp(esrGUI); %Set the amplitude
%             
%             set(esrGUI.numCompleted,'String', num2str(0));
%             
%             % create a list of frequency states in the SRS sig-gen
%             fopen(obj.srs);
%             fprintf(obj.srs, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
%             fprintf(obj.srs, '*CLS');
%             freqHz = freqValues*(10^6);
%             for i = 1:length(freqHz)
%                    % pre-load each state of the list into the SG384 memory
%                    fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(freqHz(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
%             end
%             % enable the list
%             fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
%             
%             %Initialize the DAQ to collect data
%             obj.gesr.NsamplesAcquired = 0;
%             averageYData = zeros(1,length(freqValues));
%             averageYErrorBars = zeros(1,length(freqValues));
%             %Create a pulse train to act as a clock to coordinate the
%             %counter measurements
%             obj.DAQ.CreateTask('RunningPulseTrain');
%             clockFrequency = 1/timeStep;
%             clockFrequency = clockFrequency*(10^6);
%             clockLine = 1;
%             obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.gesr.dutyCycle);
%             
%             %set counter to save a sample at each position(voltage pair)
%             %visited
%             obj.DAQ.CreateTask('RunningCounter');
%             counterLine = 1;
%             obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.gesr.NSamples);
%             
%             for j = 1:numAverages
%                 obj.gesr.counterData = [];
%                 flength = length(freqValues);
%                 
%                 % wait for tasks to start
%                 pause(0.1);
% 
%                 % start the sample clock
% 
%                 tstep = timeStep*10^-6;
%                 for i = 1:flength
%                     fprintf(obj.srs, '*TRG');                 % trigger the list
%                     obj.DAQ.StartTask('RunningCounter');
%                     obj.DAQ.StartTask('RunningPulseTrain');
%                     tic
%                     while toc < tstep
%                         %This method of waiting is used because it is far
%                         %more accurate if nothing is happening in the
%                         %background, but also can be interrupted.
%                     end
%                     %Acquire data from the DAQs
%                     NSamplesAvailable = obj.DAQ.GetAvailableSamples('RunningCounter');
%                     if NSamplesAvailable > 0 
%                         obj.gesr.counterData = [obj.gesr.counterData diff(double(obj.DAQ.ReadCounterBuffer('RunningCounter',NSamplesAvailable)))/tstep];
%                     end
%                     obj.DAQ.StopTask('RunningCounter');
%                     obj.DAQ.StopTask('RunningPulseTrain');
%                 end
%                 if obj.gesr.stopScan
%                     break
%                 end
%                 set(esrGUI.numCompleted,'String', num2str(j));
%                 
%                 %Process the data for graphing
%                 averageYErrorBars = sqrt(averageYErrorBars.^2 + ((j-1)/j)*(obj.gesr.counterData - averageYData).^2);
%                 averageYData = averageYData + (obj.gesr.counterData - averageYData)/j;
%                 
%                 %Plot the data, multiply by 0.001 for kCounts
%                 plot(currentAxes, freqValues, obj.gesr.counterData*0.001, '-.bo',...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','b');
%                 errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, '-.ro', 'LineWidth', 2.0,...
%                     'MarkerEdgeColor','k',...
%                     'MarkerFaceColor','k');
% 
%                 title(currentAxes, 'Current Scan');
%                 title(averageAxes, 'Average Scan');
%                 ylabel(currentAxes, 'PL (kCounts/s)');
%                 ylabel(averageAxes, 'PL (kCounts/s)');
%                 xlabel(currentAxes, 'Frequency (MHz)');
%                 xlabel(averageAxes, 'Frequency (MHz)');
%                 
%                 if ( mod(j, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
%                     
%                     [fid, ~] = obj.gesr.DefineESRDataSavePath(esrGUI,1);
%                     fprintf(fid, '%s\t%s\t%s\t%s\n', 'Frequency','currentSweepCountRate','AverageCountRate','Error');
%                     fprintf(fid, '%e\t%e\t%e\t%e\n', [freqValues; obj.gesr.counterData; averageYData; averageYErrorBars/j]);
%                     fclose(fid);
%                     clear fid
%                 end
%                 
%                 % create array of individual data traces for Matlab saving routine
%                 indDataTraces(j,:) = obj.gesr.counterData*0.001;
%             end
%             
%             obj.gesr.saveEsrMatFile(esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,'PerformScanPart2CWESR')
%             clear indDataTraces
%             
%             %clear the daq
%             obj.DAQ.ClearTask('RunningCounter');
%             obj.DAQ.ClearTask('RunningPulseTrain');
%             
%             fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
%             fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
%             fprintf(obj.srs, '*CLS');
%             fclose(obj.srs);
%             
%             global ESR_splitting;
%             % fit the data with the chosen conditions
%             if get(esrGUI.checkboxDoAutoFit,'Value') == 1
%                % figSweepFit = figure(obj.hSweepFitFig1);
%                % clf(figSweepFit);
%                 
%                 % use the peakfit function in the ImageScan directory
%                 % I took out the call to "figure" I had put in "peakfit.m"
%                 % so now it will use the current figure, figSweepFit
%                 
%                
%                 dataToFit1 = averageYData(1:numFreqSteps)';
%                 dataToFit1 = max(dataToFit1)-dataToFit1;
% 
%                 
%                 dataToFit2 = averageYData(numFreqSteps+1:2*numFreqSteps)';
%                 dataToFit2 = max(dataToFit2)-dataToFit2;
% 
%                 [peaks1] = peakfinder(dataToFit1, 5000);
%                 peak_list1 = [dataToFit1(peaks1) peaks1];
%                 peak_list1 = flipud(sortrows(peak_list1,1));
%                 
%                 [peaks2] = peakfinder(dataToFit2, 5000);
%                 peak_list2 = [dataToFit2(peaks2) peaks2];
%                 peak_list2 = flipud(sortrows(peak_list2,2));
%                 
%                 peakguess1 = c1_freq;
%                     if length(peak_list1) >=1
%                         peakguess1 = freqValues1(peak_list1(1,2));
%                     end
%                     
%                 peakguess2 = c2_freq;
%                     if length(peak_list2) >=1
%                         peakguess2 = freqValues2(peak_list2(1,2));
%                     end
%                 
%                    figure(6000);
%                     [CWFitResults,~] = peakfit([freqValues1' dataToFit1],0,0,1,1,0,1,[peakguess1 10]);
%                     
%                     if abs(CWFitResults(1,2)-c1_freq)<80
%                         c1_freq = CWFitResults(1,2)
%                     end
%                     
%                     
%                    figure(6001);
%                     [CWFitResults,~] = peakfit([freqValues2' dataToFit2],0,0,1,1,0,1,[peakguess2 10]);
%                     if abs(CWFitResults(1,2)-c2_freq)<80
%                         c2_freq = CWFitResults(1,2)
%                     end
%                     
%                     if (c1_freq < 2500) || (c1_freq >2885)
%                         c1_freq = c1_freq_start
%                     end
%                     if (c2_freq < 2870) || (c2_freq >3300)
%                         c2_freq = c2_freq_start
%                     end
%                  
%                     if c2_freq < c1_freq
%                         tempf = c1_freq;
%                         c1_freq = c2_freq;
%                         c2_freq = tempf;
%                     end
%                     ESR_splitting = c2_freq-c1_freq;
% %                         ESR_splitting = 2870-c1_freq;
% 
% %                     set(esrGUI.curveFreqM,'String',num2str(fms(1)));
% %                     set(esrGUI.curveFreqP,'String',num2str(fms(2)));
%                     %set(esrGUI.curveB0,'String',num2str(esrB0));
%                    % set(esrGUI.curveTheta,'String',num2str(esrTheta));
%                 else
%                      ESR_splitting = 0;
%                 
%             end
%             
%             ESR_splitting
%             obj.gesr.EnableGui(esrGUI);
%             obj.gesr.stopScan = false;
%          end
    end
    
end

