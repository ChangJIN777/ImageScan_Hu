classdef EsrGlobalMethods < handle
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       DAQ;
       srs;
       srs2;
       srs3;
       ESRControlFig;
       pulseBlaster;
       trackParameters;
       imageScanHandles;
       
       stopScan = false;
       NsamplesAcquired = 0;
       dutyCycle = 0.5;
       NSamples = 2;
       counterData = [];
       counterData2 = [];
       counterDataPerShot = []; % added for taking per shot data points
       
       fileWriteFrequency = [];
       fileWritePathname = [];
       fileWriteFilename = [];
       fileWriteFileNum = [];
    end
    
    methods
        
        function obj = EsrGlobalMethods(DAQ,PulseInterpret,SRS,SRS2,SRS3, handles)
           
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
            
       end
        
        function setAmp(obj,esrGUI)
            %Sets the Amplitude of the RF output manually.
            
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            obj.srs.set_amp(inputAmp);
%             fopen(obj.srs);
%             %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
%             fprintf(obj.srs, ['AMPR ', num2str(inputAmp)]); % Ntype
%             fclose(obj.srs);
        end
        
        function setFreq(obj, esrGUI)
            %Sets the frequency to the passed in value
            
            inputFreq = str2double(get(esrGUI.centerFreq,'String'));
            obj.srs.set_freq(inputFreq);
%             fopen(obj.srs);
%             fprintf(obj.srs,['FREQ ', num2str(inputFreq),' MHz']); % write to the SG384
%             fclose(obj.srs);
        end
        
        function setAmp2(obj,esrGUI)
            %Sets the Amplitude of the RF output manually.
            
            inputAmp = str2double(get(esrGUI.amplitudeB,'String'));
            obj.srs2.set_amp(inputAmp);
%             fopen(obj.srs);
%             %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
%             fprintf(obj.srs, ['AMPR ', num2str(inputAmp)]); % Ntype
%             fclose(obj.srs);
        end
        
        function setFreq2(obj, esrGUI)
            %Sets the frequency to the passed in value
            
            inputFreq = str2double(get(esrGUI.centerFreqB,'String'));
            obj.srs2.set_freq(inputFreq);
%             fopen(obj.srs);
%             fprintf(obj.srs,['FREQ ', num2str(inputFreq),' MHz']); % write to the SG384
%             fclose(obj.srs);
        end
        
        function setAmp3(obj,esrGUI)
            %Sets the Amplitude of the RF output manually.
            
            inputAmp = str2double(get(esrGUI.amplitudeC,'String'));
            obj.srs3.set_amp(inputAmp);
%             fclose(obj.srs);
%             fopen(obj.srs);
%             %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
%             fprintf(obj.srs, ['AMPR ', num2str(inputAmp)]); % Ntype
%             fclose(obj.srs);
        end
        
        function setFreq3(obj, esrGUI)
            %Sets the frequency to the passed in value
            
            inputFreq = str2double(get(esrGUI.centerFreqC,'String'));
            obj.srs3.set_freq(inputFreq);
%             fopen(obj.srs);
%             fprintf(obj.srs,['FREQ ', num2str(inputFreq),' MHz']); % write to the SG384
%             fclose(obj.srs);
        end
        
        function output = CheckAmp(~,amp,maxamp):
            % Display a warning when RF output amplitude exceeds the
            % maximum allowed value
            output = 0;
            if amp > maxamp
                danger = questdlg('The amplitude is high for a pulsed measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop
                    case 'Run'
                        % continue on  
                end
            end
        end
        
        function EnableGui(~, esrGUI)
            %Runs whenever a measurement is ended. Re-enables controls
            set(esrGUI.buttonStartCWESR, 'Enable', 'on');
            set(esrGUI.buttonStartSequence, 'Enable', 'on');
        end
        
        function DisableGui(~, esrGUI)
            %Runs whenever a measurement is started. Disables all controls that
            %could affect the performance of the sweep or sequence.
            set(esrGUI.buttonStartCWESR, 'Enable', 'off');
            set(esrGUI.buttonStartSequence, 'Enable', 'off');
        end
        
        function ToggleRF(obj,newValue,esrGUI)
            switch newValue
                case 0
                    fopen(obj.srs);
                    fprintf(obj.srs, ['ENBR ', '0']);
                    fclose(obj.srs);
                    set(esrGUI.checkboxWithSwitch,'Enable', 'on');
                    % pulseblaster needs to turn off pulse
                    if get(esrGUI.checkboxWithSwitch,'Value') == 1
                        
                        obj.pulseBlaster.stopPulse();
                        if obj.imageScanHandles.configS.bHaveInverterBoard == 0
                            obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                            obj.pulseBlaster.loadToPulseblaster();
                            obj.pulseBlaster.runPulse();
                        end
                    end
                case 1
                    if strcmp(questdlg('Sure you want to turn this RF on?','RF warning','Yes','KeepOff','KeepOff'), 'Yes')
                    
                        fopen(obj.srs);
                        fprintf(obj.srs, ['ENBR ', '1']);
                        fclose(obj.srs);
                        obj.setAmp(esrGUI);
                        obj.setFreq(esrGUI);
                        set(esrGUI.checkboxWithSwitch,'Enable', 'off');
                        if get(esrGUI.checkboxWithSwitch,'Value') == 1
                            if obj.imageScanHandles.configS.bHaveInverterBoard == 1
                                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit3_on.txt']);
                            else
                                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_3_on.txt']);
                            end
                            obj.pulseBlaster.loadToPulseblaster();
                            obj.pulseBlaster.runPulse();
                        end
                    else
                        set(esrGUI.togglebuttonRF,'Value',0);
                    end
                   
           end        
        end
        
        function IQmodulationON(obj, newValue)
           % fclose(obj.srs);
           % Currently only allowing IQ modulation on SRS1
            switch newValue
                case 0
                    obj.srs.set_IQ_off(); % disable IQ modulation
                case 1
                     obj.srs.set_IQ_on(); % enable IQ modulation
            end
        end
        
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end  
        
        % ----- ESR file number update --------------------------------------------------------
        function UpdateFileNumber(~, esrGUI, ~)
            % sequence that checks what the last file # in the current Data folder is and
            % adds +1 to that (updated 06April2017,SB)
            fileDateFolder = get(esrGUI.esrSavePath,'String');
            d = dir([fileDateFolder '*.mat']);
            [~,newestIndex] = max([d.datenum]); % find the newest file
            if isempty(newestIndex)
                imageSaveCounter = '000000';
            else
                newestFile = d(newestIndex).name;
                k = strfind(newestFile,'_');
                if max(size(k))>= 2
                    imageSaveCounter = newestFile(k(end-2)+1:k(end-1)-1);
                else
                    imageSaveCounter = newestFile(k(end-1)-7:k(end-1)-1); % this case should not happen but if it does, just assume the number is 6 digits long
                end
    
            end
            imageSaveCounter = sprintf('_%06d', str2double(imageSaveCounter)+1); % add 1 to last counter
            set(esrGUI.esrSaveFileNum,'String', imageSaveCounter);
        
            clear fileDateFolder d newestIndex k* newestFile* imageSaveCounter oldPrefixSize
        end
        
        % ----- automatic save folder update --------------------------------------------------
        function UpdateFolder(obj, esrGUI)
            % the following sequence checks if the save folder is at the current date 
            % when starting a sweep in case it is not, it updates the gui and 
            % creates the new folder (added 06/April/2017,SB)
            d = datestr(now,'yyyy_mmm_dd');
            fileDateFolder = get(esrGUI.esrSavePath,'String');

            if ~strcmp(fileDateFolder(end-11:end-1),d) % compare date strings if not equal update in GUI and create folder
                newfileDateFolder = [fileDateFolder(1:end-12) d '\']; % warining, in case the whole date save path structure changes, this line might mess up and might need to be reprogrammed
    
                set(esrGUI.esrSavePath,'String', newfileDateFolder);
                obj.fileWritePathname = [newfileDateFolder '\'];
                fileDateFolder = newfileDateFolder;
            end
            if exist(fileDateFolder,'dir') ~= 7 % if directory exists matlab returns 7
                mkdir(fileDateFolder)
            end
            clear d fileDateFolder newfileDateFolder
        end
            
        
        function RunSingleTrackCWESR(obj,timeStep, handles)

                    obj.DAQ.ClearTask('RunningCounter');
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    handles.StateControl.changeToTrackingState(handles,0,true);
                    
                    %Re-initialize the daq to just acquire data normally
                    obj.DAQ.CreateTask('RunningPulseTrain');
                    clockFrequency = 1/timeStep;
                    clockFrequency = clockFrequency*(10^6);
                    clockLine = 1;
                    obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,obj.dutyCycle);

                    %set counter to save a sample at each position(voltage pair)
                    %visited
                    obj.DAQ.CreateTask('RunningCounter');
                    counterLine = 1;
                    obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,obj.NSamples);
                    
                    handles.StateControl.changeToIdleState(handles,6);
        end
        
        function RunSingleTrackPulsedESR(obj, handles)

                    obj.DAQ.ClearTask('RunningCounter');
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    handles.StateControl.changeToTrackingState(handles, 0, true);                  
                    handles.StateControl.changeToIdleState(handles,6);
        end
        
        
        function GetCountsUntilBuffersFilled(obj,numSigBuffers)
            
            iCD = 1;
            if (numSigBuffers == 1)
                
                while (obj.DAQ.IsTaskDone('Counter') == false && obj.stopScan == false) 
                   
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                    
                    if NSamplesAvailable > 0
                        %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                        % save problems with allocation blocks by
                        % preallocating counterData
                        obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                        iCD = iCD + NSamplesAvailable;
                    end
                    pause(0.001);
                end
                    
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                if NSamplesAvailable > 0
                    %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                    obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                    iCD = iCD + NSamplesAvailable;
                end
            end
            
             if (numSigBuffers == 2)
                while (obj.DAQ.IsTaskDone('Counter1') == false && obj.stopScan == false) 
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter1');
                    if NSamplesAvailable > 0
                        %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                        % save problems with allocation blocks by
                        % preallocating counterData
                        obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter1',NSamplesAvailable);
                        iCD = iCD + NSamplesAvailable;
                    end
                    pause(0.1);
                end
                    
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter1');
                if NSamplesAvailable > 0
                    %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                    obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter1',NSamplesAvailable);
                    iCD = iCD + NSamplesAvailable;
                end
             end
             
        end
        
         function GetCountsUntilBuffersFilledTwoCounter(obj,numSigBuffers)
            %disp('getting counts2')
            iCD = 1;
            jCD = 1;
             if (numSigBuffers == 2)
                while obj.DAQ.IsTaskDone('Counter') == false || obj.DAQ.IsTaskDone('Counter2') == false
                        if obj.stopScan == true
                            break;
                        end
                        NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                        NSamplesAvailable2 = obj.DAQ.GetAvailableSamples('Counter2');
                        if NSamplesAvailable > 0
                            %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                            obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                            iCD = iCD + NSamplesAvailable;
                        end
                        if NSamplesAvailable2 > 0
                            %obj.counterData2 = [obj.counterData2 obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable2)];
                            obj.counterData2(1,jCD:(jCD+NSamplesAvailable2-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable2);
                            jCD = jCD + NSamplesAvailable2;
                        end
                        pause(0.1);
                end
                    
                    
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                NSamplesAvailable2 = obj.DAQ.GetAvailableSamples('Counter2');
                if NSamplesAvailable > 0
                    %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                    obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable);
                    iCD = iCD + NSamplesAvailable;
                end
                if NSamplesAvailable2 > 0
                    %obj.counterData2 = [obj.counterData2 obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable2)];
                    obj.counterData2(1,jCD:(jCD+NSamplesAvailable2-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable2);
                    jCD = jCD + NSamplesAvailable2;
                end
            end
        end
        
        function [fileIdentifier1,fileIdentifier2] = DefineESRDataSavePath(obj, esrGUI,numSigBuffers)
            
            if (numSigBuffers == 1)
                
                saveToFullPath = [obj.fileWritePathname obj.fileWriteFilename obj.fileWriteFileNum '\'];
                %saveToFullPath = [obj.fileWritePathname '\'];
                saveToPathFile = [ saveToFullPath obj.fileWriteFilename obj.fileWriteFileNum '_' get(esrGUI.numCompleted,'String') '.txt']; 
                if exist(obj.fileWritePathname,'dir') ==0 %path does not exist?
                    mkdir(obj.fileWritePathname);
                end
                if exist(saveToFullPath,'dir') ==0 %path does not exist?
                    mkdir(saveToFullPath);
                end

                fileIdentifier1 = fopen(saveToPathFile, 'w');
                fileIdentifier2 = -1;
            end
            
            if (numSigBuffers == 2)
                saveToFullPath = [obj.fileWritePathname obj.fileWriteFilename obj.fileWriteFileNum '\'];
                %saveToFullPath = [obj.fileWritePathname '\'];
                saveToPathFile = [ saveToFullPath obj.fileWriteFilename obj.fileWriteFileNum '_1_' get(esrGUI.numCompleted,'String') '.txt'];
                saveToPathFile2 = [ saveToFullPath obj.fileWriteFilename obj.fileWriteFileNum '_2_' get(esrGUI.numCompleted,'String') '.txt'];
                if exist(obj.fileWritePathname,'dir') ==0 %path does not exist?
                    mkdir(obj.fileWritePathname);
                end
                if exist(saveToFullPath,'dir') ==0 %path does not exist?
                    mkdir(saveToFullPath);
                end

                fileIdentifier1 = fopen(saveToPathFile, 'w');
                fileIdentifier2 = fopen(saveToPathFile2, 'w');
            end
        end
        
        % ----- ESR file save to a .mat file --------------------------------------------------
        function saveEsrMatFile(obj,esrGUI,freqValues,averageYData,averageYErrorBars,indDataTraces,CWESRtype)
        global oldPrefix
        global Img_handles
                
            %sequence to save ESR CW files as .mat file
%             [Tmagnet, Tsample] = readOxfordTemp;
%             [Bx,By,Bz] = readMagField;
            
            CW.param.FileName = [obj.fileWriteFilename obj.fileWriteFileNum '_' datestr(now,'yyyymmdd_HHMM')] ;
            CW.param.FilePath = obj.fileWritePathname;
            CW.param.CenterFreq = str2double(get(esrGUI.centerFreq, 'String')); %center frequency in MHz
            CW.param.SweepRange = CW.param.CenterFreq + str2double(get(esrGUI.CWFreqDeviation, 'String'))*[-1 1]; %[fmin fmax]
            CW.param.numFreqSteps = str2double(get(esrGUI.numFreqSteps, 'String')); %number of measurement points
            CW.param.DwellTime = str2double(get(esrGUI.timePerFreqStep, 'String')); %dwell time in micro-seconds
            CW.param.RFAmplitude = str2double(get(esrGUI.amplitude,'String')); %set RF amplitude
            CW.param.numSweeps = size(indDataTraces,1); %num of completed sweeps
            CW.param.repsPerTau = str2double(get(esrGUI.repsPerTau,'String')); % pulse repetition (e.g. used in when scanning CW-ESR-diff)
            CW.param.CWESRtype = CWESRtype; % type of CWESR sweep used (different functions in EsrCWSweep
            CW.param.opticalP = str2double(get(Img_handles.greenPowerString, 'String'))*1e6; % optical power in [W]
%             if ~isempty(CWESRtype)
%                 CW.param.ESRScanPulseSequence = Img_handles.pulseSequence;
%             end
            CW.param.ConfocalSpotPosition = [str2double(get(obj.imageScanHandles.editPositionX,'String')) str2double(get(obj.imageScanHandles.editPositionY,'String')) str2double(get(obj.imageScanHandles.editPositionZ,'String'))]; % cursor position in [micrometer]
%             CW.param.Tsample = Tsample; % sample temperature in [K]
%             CW.param.Tmagnet = Tmagnet; % magnet temperature in [K]
%             CW.param.magField = [Bx By Bz]; % magnetic field in [G]
            CW.param.trackingPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String')); %tracking occured after x number of sweeps
            CW.param.trackParameters = obj.trackParameters; % save all tracking parameters in bulk
            CW.param.InverterBoard = obj.imageScanHandles.configS.bHaveInverterBoard; %0 = no board, 1 = inverter board
            CW.param.PulseBlasterInstructions = obj.pulseBlaster.currentInstruction; %saved PulseBlaster instructions
            CW.param.tipDiamond = get(obj.imageScanHandles.tipDiamond,'String');
            CW.param.sample = get(obj.imageScanHandles.sample,'String');
            
            CW.data.freqValues = freqValues; %array with frequencies in MHz
            CW.data.averageCounts = averageYData*0.001; %averaged counts in kcounts/s 
            CW.data.averageError = averageYErrorBars*0.001/CW.param.numSweeps; %averaged errorbars in kcounts/s
            
            CW.data.individualSweeps = indDataTraces;

            save([CW.param.FilePath CW.param.FileName '.mat'],'CW')
            
            oldPrefix = obj.fileWriteFilename; % kept here in case this is used somewhere else
%             disp('saving ESR file to .mat format')
        end
        
        function saveDiffEsrMatFile(obj,esrGUI,freqValues,averageContrast,averageContrastError,contrast,countDiff,countTotal,CWESRtype)
        global oldPrefix
        global Img_handles
                
            %sequence to save ESR CW files as .mat file
            [Tmagnet, Tsample] = readOxfordTemp;
%             [Bx,By,Bz] = readMagField;
            
            CW.param.FileName = [obj.fileWriteFilename obj.fileWriteFileNum '_' datestr(now,'yyyymmdd_HHMM')] ;
            CW.param.FilePath = obj.fileWritePathname;
            CW.param.CenterFreq = str2double(get(esrGUI.centerFreq, 'String')); %center frequency in MHz
            CW.param.SweepRange = CW.param.CenterFreq + str2double(get(esrGUI.CWFreqDeviation, 'String'))*[-1 1]; %[fmin fmax]
            CW.param.numFreqSteps = str2double(get(esrGUI.numFreqSteps, 'String')); %number of measurement points
            CW.param.DwellTime = str2double(get(esrGUI.timePerFreqStep, 'String')); %dwell time in micro-seconds
            CW.param.RFAmplitude = str2double(get(esrGUI.amplitude,'String')); %set RF amplitude
            CW.param.numSweeps = size(contrast,1); %num of completed sweeps
            CW.param.repsPerTau = str2double(get(esrGUI.repsPerTau,'String')); % pulse repetition (e.g. used in when scanning CW-ESR-diff)
            CW.param.CWESRtype = CWESRtype; % type of CWESR sweep used (different functions in EsrCWSweep
            CW.param.opticalP = str2double(get(Img_handles.greenPowerString, 'String'))*1e6; % optical power in [W]
%             if ~isempty(CWESRtype)
%                 CW.param.ESRScanPulseSequence = Img_handles.pulseSequence;
%             end
            CW.param.ConfocalSpotPosition = [str2double(get(obj.imageScanHandles.editPositionX,'String')) str2double(get(obj.imageScanHandles.editPositionY,'String')) str2double(get(obj.imageScanHandles.editPositionZ,'String'))]; % cursor position in [micrometer]
            CW.param.Tsample = Tsample; % sample temperature in [K]
            CW.param.Tmagnet = Tmagnet; % magnet temperature in [K]
%             CW.param.magField = [Bx By Bz]; % magnetic field in [G]
            CW.param.trackingPeriod = str2double(get(esrGUI.cwTrackingPeriod,'String')); %tracking occured after x number of sweeps
            CW.param.trackParameters = obj.trackParameters; % save all tracking parameters in bulk
            CW.param.InverterBoard = obj.imageScanHandles.configS.bHaveInverterBoard; %0 = no board, 1 = inverter board
            CW.param.PulseBlasterInstructions = obj.pulseBlaster.currentInstruction; %saved PulseBlaster instructions
            CW.param.tipDiamond = get(obj.imageScanHandles.tipDiamond,'String');
            CW.param.sample = get(obj.imageScanHandles.sample,'String');
            
            CW.data.freqValues = freqValues; %array with frequencies in MHz
            CW.data.averageContrast = averageContrast;
            CW.data.averageContrastError = averageContrastError/CW.param.numSweeps; %averaged errorbars in kcounts/s
            CW.data.contrast = contrast;
            CW.data.countDiff = countDiff;
            CW.data.countTotal = countTotal;

            save([CW.param.FilePath CW.param.FileName '.mat'],'CW')
            
            oldPrefix = obj.fileWriteFilename;
%             disp('saving ESR file to .mat format')
        end
            
    end
    
end

