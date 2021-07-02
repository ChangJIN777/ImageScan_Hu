classdef EsrCWSweep < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       DAQ;
       srs;
       ESRControlFig;
       pulseBlaster;
       gesr;
       trackParameters;
       imageScanHandles;
       hSweepFitFig1=1123235;
    end
    
    methods
        function obj = EsrCWSweep(handles, DAQ,PulseInterpret,SRS,gESR)
           
           % handle to the AFM GUI called in ImageScan 
           % this is useless though since that GUI is not opened yet = []
            obj.ESRControlFig = handles.ESRControl;
            obj.imageScanHandles = handles;
           
            obj.DAQ = DAQ; % most likely result, used passed arg
            
            % these devices already have handles, which are passed in
            obj.pulseBlaster = PulseInterpret;
            obj.srs = SRS;
            obj.trackParameters = handles.ScanControl.TrackingParameters;            
            obj.gesr = gESR;
        end
       
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
        
        function PerformCWESR(obj,esrGUI)
            % update the file number to prevent saving over your data
            obj.gesr.UpdateFileNumber(esrGUI);
            
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            if inputAmp > -10
                danger = questdlg('The amplitude is high for a cw esr measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop

                    case 'Run'
                        % continue on  
                end
            end
            
            checkTask = questdlg('did you remember to stop all running count tasks?','Conflicting tasks warning','Abort','Run','Abort');
            switch(checkTask)
                case 'Abort'
                    return
                    % exit the perform sequence if user chooses to stop

                case 'Run'
                    % continue on  
            end
            
            % in case there is any frequency modulation, turn off.
          %fclose(obj.srs);
            fopen(obj.srs);
            fprintf(obj.srs, 'MODL0');
            fclose(obj.srs);
            
            % get some parameters from string inputs on the ESR GUI
            centerFreq = str2num(get(esrGUI.centerFreq, 'String'));
            centerFreqB = str2num(get(esrGUI.centerFreqB,'String'));
            numFreqSteps = str2num(get(esrGUI.numFreqSteps, 'String'));
            numAverages = str2num(get(esrGUI.numAverages, 'String'));
            timeStep = str2num(get(esrGUI.timePerFreqStep, 'String'));
            freqdev = str2num(get(esrGUI.CWFreqDeviation, 'String'));
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            freqSweepRangeB = centerFreqB + freqdev*[-1,1];
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            trackPeriod = str2num(get(esrGUI.cwTrackingPeriod,'String'));
            obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
            % depending on inverter board being installed, set sequence
            if obj.imageScanHandles.configS.bHaveInverterBoard==1%get(esrGUI.checkboxAOMInverter,'Value')==1
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit3_on.txt']);
            else
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_3_4_on.txt']);
            end
            obj.pulseBlaster.loadToPulseblaster();
            obj.pulseBlaster.runPulse();
            
            
            % enable the Ntype SRS output, disable the low frequency BNC
            fopen(obj.srs);
            fprintf(obj.srs, ['ENBL ', '0']);
            fprintf(obj.srs, ['ENBR ', '1']);
            fclose(obj.srs);
            
            obj.gesr.stopScan = false; % Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI);      % Disable the GUI while running
            if get(esrGUI.checkbox_twoRFSweeps,'Value')
                % two center frequencies, ideally NOT overlapping in range
                freqValuesB = linspace(freqSweepRangeB(1), freqSweepRangeB(2), numFreqSteps);
                freqValuesA = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
                freqValues = [freqValuesA, freqValuesB];
            else
                % usual operation is a single sweep range
                freqValues = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps);
            end
            obj.gesr.setAmp(esrGUI); %Set the amplitude
            
            set(esrGUI.numCompleted,'String', num2str(0));
            
            % create a list of frequency states in the SRS sig-gen
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
                flength = length(freqValues); % allows variable number of frequency values beyond "numFreqSteps"
                
                % wait for tasks to start
                pause(0.1);

                % start the sample clock

                tstep = timeStep*10^-6;
                for i = 1:flength
                    fprintf(obj.srs, '*TRG');                 % trigger the list
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
                errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, 'ro', 'LineWidth', 2.0,...
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
            end
            
            %clear the daq
            obj.DAQ.ClearTask('RunningCounter');
            obj.DAQ.ClearTask('RunningPulseTrain');
            
            %Turn off pulse and clear class, Clear out the RF generator
            bLeaveRFOn=0;
            if ~bLeaveRFOn
                obj.pulseBlaster.stopPulse();
                if obj.imageScanHandles.configS.bHaveInverterBoard==0
                    % no inverter board so by default have laser back on
                    obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                    obj.pulseBlaster.loadToPulseblaster();
                    obj.pulseBlaster.runPulse();
                end
            end
            fprintf(obj.srs,'LSTE 0');  % 1 or 0 for enabled or disabled
            fprintf(obj.srs, 'LSTD');   % destroy the list after sweep
            fprintf(obj.srs, '*CLS');
            if ~bLeaveRFOn
                fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
            end
            fclose(obj.srs);
            
            % fit the data with the chosen conditions
            if get(esrGUI.checkboxDoAutoFit,'Value') == 1
                figSweepFit = figure(obj.hSweepFitFig1);
                clf(figSweepFit);
                
                % 3-13-2014 - find out how many peaks there are with some
                % threshold for minimum peak height, maybe this can depend
                % on the error bar values.
                hyperfineExpected = get(esrGUI.checkboxExpectHyperfine,'Value');
                PositiveCounts = mean(averageYData) - averageYData';
                TwoSigma = 2*mean(averageYErrorBars/j); % want peaks some number of sigmas above the mean
                ThreeSigma = 3*mean(averageYErrorBars/j);
                FourSigma = 4*mean(averageYErrorBars/j);
                FreqDiff = diff(freqValues);
                FreqStepSize=FreqDiff(3);
                MinimumExpectedFSpacing = 7.8; % in MHz
                minPeakSep = floor(MinimumExpectedFSpacing/FreqStepSize)
                [peakCounts,locPeaks] = findpeaks(PositiveCounts,'MINPEAKHEIGHT',FourSigma,'MINPEAKDISTANCE',minPeakSep);
                
                % use the peakfit function in the ImageScan directory
                % I took out the call to "figure" I had put in "peakfit.m"
                % so now it will use the current figure, figSweepFit
                numPeaksToFit = length(peakCounts);
                numPeaksToFit
                peakCounts
                locPeaks
                freqValues(locPeaks)
                wth = 10; % guess in MHz the peak width starting value.
                if numPeaksToFit == 0
                    % default will be two peaks...
                    % another default could be to keep counting with lower
                    % max peak height until peaks are found
                    guessArray = [2869 wth 2871 wth];
                    numPeaksToFit = 2;
                else
                    % build up the appropriate-length array [center1,
                    % width1,...] for initial guesses of each peak
                    guessArray = [];
                    for np = 1:numPeaksToFit
                        guessArray = [guessArray freqValues(locPeaks(np)) wth];
                    end
                end
                set(esrGUI.outNumPeaksFound,'String',num2str(numPeaksToFit));
                dataToFit = averageYData';
                baselineValues = [dataToFit(1:6)', dataToFit((end-5):end)'];
                baselineFreqs = [freqValues(1),freqValues(end)];
                errorbar(averageAxes, freqValues, averageYData*0.001,averageYErrorBars*0.001/j, '-.ro', 'LineWidth', 2.0,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','k');
                hold on
                plot(averageAxes,baselineFreqs,mean(baselineValues)*[1,1]*0.001,'b--');
                hold off
                dataToFit = mean(baselineValues)-dataToFit;
                [CWFitResults,~,~,~,~]=...
                    peakfit([freqValues' dataToFit],0,0,numPeaksToFit,2,0,16,guessArray,1);
                
                
                % to pair peaks together in a field calculation, first for
                % an even number of peaks find the two that are closest to
                % the Dsplitting value, then the next two farthest, etc...
                Dsplitting = str2double(get(esrGUI.Dsplitting,'String'));
                fms = [];
                tableFreq = [];
                tableWidth = [];
                tablePair = [];
                tableB0 = [];
                tableTheta = [];
                for np=1:numPeaksToFit
                    fms = [fms CWFitResults(np,2)];
                end
                [fms findex] = sort(fms); % sort in ascending order
                sWidth = CWFitResults(findex,4);
                
                if mod(numPeaksToFit,2)
                    %odd num. Peaks
                    if hyperfineExpected==0
                        for pp=1:numPeaksToFit
                           freq1 = fms(pp);
                           tableFreq = [tableFreq; freq1];
                           tableWidth = [tableWidth; sWidth(pp)];
                           tablePair = [tablePair; pp];
                            esrB0 = 0; esrTheta = 0;
                            tableB0 = [tableB0; esrB0];
                            tableTheta = [tableTheta; esrTheta];
                        end

                        dataMatrix = [tableFreq,tableWidth,tablePair,tableB0,tableTheta];
                        set(esrGUI.esrResultsTable,'Data',dataMatrix); 
                    end
                else
                    %even num. peaks
                    if hyperfineExpected==0
                        % all peaks must be +/-1 of NV orientations
                        for pp = 1:numPeaksToFit/2
                           % loop through all pairs
                           % the first pair is always given by (fms(1) and
                           % fms(end)
                           freqL = fms(pp); % 1,2,3,4...on each loop
                           freqR = fms(end-pp+1); %8,7,6,5... on each loop
                           tableFreq = [tableFreq; freqL; freqR];
                           tableWidth = [tableWidth; sWidth(pp); sWidth(end-pp+1)];
                           tablePair = [tablePair; pp; pp];
                           esrP = 0; esrQ = 0; 
                           if (freqL~=0) && (freqR~=0)
                                esrP = freqL^2 + freqR^2 - freqL*freqR;
                                esrQ = (freqL+freqR)*(2*freqL^2+2*freqR^2-5*freqL*freqR);
                                esrB0 = sqrt((esrP-Dsplitting^2)/3);
                                esrTheta = acos(sqrt((esrQ+9*Dsplitting*esrB0^2+2*Dsplitting^3)/(27*Dsplitting*esrB0^2)));
                                esrTheta = esrTheta*180/pi; % radians->degrees
                                esrB0 = esrB0/2.7992; %~2.8 MHz/ Gauss to convert-> Gauss
                           else
                                esrB0 = 0; esrTheta = 0;
                           end
                           tableB0 = [tableB0; esrB0; esrB0];
                           tableTheta = [tableTheta; esrTheta; esrTheta];
                           
                        end
                        dataMatrix = [tableFreq,tableWidth,tablePair,tableB0,tableTheta];
                        set(esrGUI.esrResultsTable,'Data',dataMatrix);
                    end
                    
                end
                
               
            end
            
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
            
            % for AFM calls, this '0' signals measurement is complete
            set(esrGUI.writeDataFreq,'UserData',0); 
        end
    end
    
end

