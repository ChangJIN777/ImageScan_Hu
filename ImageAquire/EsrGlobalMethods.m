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
       counterDataPerShot = [];
       
       fileWriteFrequency = [];
       fileWritePathname = [];
       fileWriteFilename = [];
       fileWriteFileNum = [];
    end
    
    methods
        
        function obj = EsrGlobalMethods(DAQ,PulseInterpret,SRS, handles)
           
           % handle to the AFM GUI called in ImageScan 
           % this is useless though since that GUI is not opened yet = []
            obj.ESRControlFig = handles.ESRControl;
            obj.imageScanHandles = handles;
           
            obj.DAQ = DAQ; % most likely result, used passed arg
            
            % these devices already have handles, which are passed in
            obj.pulseBlaster = PulseInterpret;
            obj.srs = SRS;
            obj.srs2 = handles.srs2;
            obj.srs3 = handles.srs3;
            obj.trackParameters = handles.ScanControl.TrackingParameters;            
            
       end
        
        function setAmp(obj,esrGUI)
            %Sets the Amplitude of the RF output manually.
            
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            fopen(obj.srs);
            %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
            fprintf(obj.srs, ['AMPR ', num2str(inputAmp)]); % Ntype
            fclose(obj.srs);
            
            obj.imageScanHandles.bUseSRS2=0; %Dolev--Oct 27 2018, changed back to 1. using 2 srs.
            obj.imageScanHandles.bUseSRS3=0; %Zhiran, Dolev, Jan 30 2019.
            if obj.imageScanHandles.bUseSRS2
                inputAmpB = str2double(get(esrGUI.amplitudeB,'String'));
                fopen(obj.srs2);
                %fprintf(obj.srs2, ['AMPL ', num2str(obj.amplitude)]); % bnc
                fprintf(obj.srs2, ['AMPR ', num2str(inputAmpB)]); % Ntype
                fclose(obj.srs2);   
            end
            if obj.imageScanHandles.bUseSRS3
                inputAmpC = str2double(get(esrGUI.amplitudeC,'String'));
                fopen(obj.srs3);
                %fprintf(obj.srs3, ['AMPL ', num2str(obj.amplitude)]); % bnc
                fprintf(obj.srs3, ['AMPR ', num2str(inputAmpC)]); % Ntype
                fclose(obj.srs3);   
            end
        end
        
        function setFreq(obj, esrGUI)
            %Sets the frequency to the passed in value
            
            inputFreq = str2double(get(esrGUI.centerFreq,'String'));
            fopen(obj.srs);
            fprintf(obj.srs,['FREQ ', num2str(inputFreq),' MHz']); % write to the SG384
            fclose(obj.srs);
            
            %obj.imageScanHandles.bUseSRS2=0;
            if obj.imageScanHandles.bUseSRS2
                inputFreqB = str2double(get(esrGUI.centerFreqB,'String'));
                fopen(obj.srs2);
                fprintf(obj.srs2,['FREQ ', num2str(inputFreqB),' MHz']); % write to the SG384
                fclose(obj.srs2);
            end
            if obj.imageScanHandles.bUseSRS3
                inputFreqC= str2double(get(esrGUI.centerFreqC,'String'));
                fopen(obj.srs3);
                fprintf(obj.srs3,['FREQ ', num2str(inputFreqC),' MHz']); % write to the SG384
                fclose(obj.srs3);
            end
        end
        
        function setPhaseNoise(obj, esrGUI, bOn)
            % for SRS1
            if bOn
                inputModRate_kHz = get(esrGUI.phaseNoiseRate,'String'); 
                inputModDev_deg = get(esrGUI.phaseNoiseDev,'String');
                fopen(obj.srs);
                fprintf (obj.srs, 'TYPE 2');
                fprintf(obj.srs,['RATE ',inputModRate_kHz,' kHz']);
                fprintf(obj.srs,['PNDV ',inputModDev_deg]);
                fprintf(obj.srs,'MFNC 4'); %0=sine,1=ramp,2=triangle,3=square,4=noise
                fprintf(obj.srs,['MODL ','1']);
                fclose(obj.srs);
            else
                fopen(obj.srs);
                fprintf(obj.srs,['MODL ','0']);
                fclose(obj.srs);
            end
            
        end
        function setPhaseNoiseB(obj, esrGUI, bOn)
            % for SRS2
            if bOn
                inputModRate_kHz = get(esrGUI.phaseNoiseRate,'String'); 
                inputModDev_deg = get(esrGUI.phaseNoiseDev,'String');
                fopen(obj.srs2);
                fprintf (obj.srs2, 'TYPE 2');
                fprintf(obj.srs2,['RATE ',inputModRate_kHz,' kHz']); % for noise it sets bandwidth
                fprintf(obj.srs2,['PNDV ',inputModDev_deg]);
                fprintf(obj.srs2,'MFNC 4'); %0=sine,1=ramp,2=triangle,3=square,4=noise, 5 external
                fprintf(obj.srs2,['MODL ','1']);
                fclose(obj.srs2);
            else
                fopen(obj.srs2);
                fprintf(obj.srs2,['MODL ','0']);
                fclose(obj.srs2);
            end
            
        end
        
        function EnableGui(obj, esrGUI)
            %Runs whenever a measurement is ended. Re-enables controls
            set(esrGUI.buttonStartCWESR, 'Enable', 'on');
            set(esrGUI.buttonStartSequence, 'Enable', 'on');
        end
        
        function DisableGui(obj, esrGUI)
            %Runs whenever a measurement is started. Disables all controls that
            %could affect the performance of the sweep or sequence.
            set(esrGUI.buttonStartCWESR, 'Enable', 'off');
            set(esrGUI.buttonStartSequence, 'Enable', 'off');
        end
        
        function ToggleRF(obj,newValue,esrGUI)
            newValue=get(esrGUI.togglebuttonRF,'UserData');
            if newValue==0 
                newValue=1;
                
            elseif newValue==1
                newValue=0;
            else
                newValue=0;
            end
            set(esrGUI.togglebuttonRF,'UserData',newValue);
            switch newValue
                case 0
                    'go'
                    fopen(obj.srs);
                    fprintf(obj.srs, ['ENBR ', '0']);
                    fclose(obj.srs);
                    
                   % fopen(obj.srs2);
                    %fprintf(obj.srs2, ['ENBR ', '0']);
                   % fclose(obj.srs2);
                    
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
                    'no go'
                    if strcmp(questdlg('Sure you want to turn this RF on?','RF warning','Yes','KeepOff','KeepOff'), 'Yes')
                    
                        fopen(obj.srs);
                        fprintf(obj.srs, ['ENBR ', '1']);
                        fclose(obj.srs);
                        obj.setAmp(esrGUI);
                        obj.setFreq(esrGUI);
                        
                        %settings for SRS 2
                     %    fopen(obj.srs2);
                     %   fprintf(obj.srs2, ['ENBR ', '1']);
                       % fclose(obj.srs2);
                        %obj.setAmp(esrGUI);
                        %obj.setFreq(esrGUI);
                        
                        set(esrGUI.checkboxWithSwitch,'Enable', 'off');
                        %if get(esrGUI.checkboxWithSwitch,'Value') == 1
                            if obj.imageScanHandles.configS.bHaveInverterBoard == 1
                                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit3_on.txt']);
                            else
                                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_3_4_on.txt']);
                            end
                            obj.pulseBlaster.loadToPulseblaster();
                            obj.pulseBlaster.runPulse();
                        %end
                    else
                        set(esrGUI.togglebuttonRF,'Value',0);
                    end
                   
           end        
        end
        
        function IQmodulationON(obj, newValue)
           % fclose(obj.srs);
            switch newValue
                case 0
                    fopen(obj.srs);
                    fprintf(obj.srs, ['MODL ', '0']);
                    fclose(obj.srs);
                case 1
                     fopen(obj.srs);
                     fprintf(obj.srs, ['MODL ', '1']);
                     fprintf(obj.srs, ['TYPE ', '6']);
                     fprintf(obj.srs, ['QFNC ', '5']);
                     fclose(obj.srs);
            end
            
          %  bUseSRS2=0
            if obj.imageScanHandles.bUseSRS2
                switch newValue
                    case 0
                        fopen(obj.srs2);
                        fprintf(obj.srs2, ['MODL ', '0']);
                        fclose(obj.srs2);
                    case 1
                         fopen(obj.srs2);
                         fprintf(obj.srs2, ['MODL ', '1']);
                         fprintf(obj.srs2, ['TYPE ', '6']);
                         fprintf(obj.srs2, ['QFNC ', '5']);
                         fclose(obj.srs2);
                end
            end
            
            if obj.imageScanHandles.bUseSRS3
                switch newValue
                    case 0
                        fopen(obj.srs3);
                        fprintf(obj.srs3, ['MODL ', '0']);
                        fclose(obj.srs3);
                    case 1
                         fopen(obj.srs3);
                         fprintf(obj.srs3, ['MODL ', '1']);
                         fprintf(obj.srs3, ['TYPE ', '6']);
                         fprintf(obj.srs3, ['QFNC ', '5']);
                         fclose(obj.srs3);
                end
            end
        end
        
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
        
        function UpdateFileNumber(obj, esrGUI, handles)
            imageSaveCounter = str2num(get(esrGUI.esrSaveFileNum,'String'));
            imageSaveCounter = imageSaveCounter+1;
            if imageSaveCounter >99999
               imageSaveCounter = 0; 
            end
            padded0Str = sprintf('%05d', imageSaveCounter); % pad with zeroes for 5 digits (100,000 images)
            set(esrGUI.esrSaveFileNum,'String', padded0Str);
        end
        
        function RunSingleTrackCWESR(obj,timeStep, handles)

                    obj.DAQ.ClearTask('RunningCounter');
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    handles.StateControl.changeToTrackingState(handles, true);
                    
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
        end
        
        function RunSingleTrackPulsedESR(obj, handles)

                    obj.DAQ.ClearTask('RunningCounter');
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    handles.StateControl.changeToTrackingState(handles, true);
%                      obj.DAQ.ClearTask('RunningCounter');
%                     obj.DAQ.ClearTask('RunningPulseTrain');
%                     handles.StateControl.changeToTrackingState(handles, true);
        end
        
        
        function GetCountsUntilBuffersFilled(obj,numSigBuffers)
            
            iCD = 1;
            jCD = 1;
            if (numSigBuffers == 1)
                
                while (obj.DAQ.IsTaskDone('Counter2') == false && obj.stopScan == false) 
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter2');
                    if NSamplesAvailable > 0
                        %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                        % save problems with allocation blocks by
                        % preallocating counterData
                        obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable);
                        iCD = iCD + NSamplesAvailable;
                    end
                    pause(0.1);
                end
                    
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter2');
                if NSamplesAvailable > 0
                    %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                    obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable);
                    iCD = iCD + NSamplesAvailable;
                end
            end
            
            if (numSigBuffers == 2)
                while (obj.DAQ.IsTaskDone('Counter2') == false && obj.stopScan == false) 
                    NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter2');
                    if NSamplesAvailable > 0
                        %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                        % save problems with allocation blocks by
                        % preallocating counterData
                        obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable)
                        iCD = iCD + NSamplesAvailable;
                    end
                    pause(0.1);
                end
                    
                NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter2');
                if NSamplesAvailable > 0
                    %obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                    obj.counterData(1,iCD:(iCD+NSamplesAvailable-1)) = obj.DAQ.ReadCounterBuffer('Counter2',NSamplesAvailable);
                    iCD = iCD + NSamplesAvailable;
                end
            end
        end
        
        function [fileIdentifier1,fileIdentifier2] = DefineESRDataSavePath(obj, esrGUI,numSigBuffers)
            
            if (numSigBuffers == 1)
                
                saveToFullPath = [obj.fileWritePathname obj.fileWriteFilename obj.fileWriteFileNum '\'];
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
            
            % do a "fake" value for numSigBuffers input to indicate analog
            % laser power save file
            if (numSigBuffers <0)
                
                saveToFullPath = [obj.fileWritePathname obj.fileWriteFilename obj.fileWriteFileNum '\'];
                if numSigBuffers == -5
                    saveToPathFile = [ saveToFullPath obj.fileWriteFilename obj.fileWriteFileNum '_laserPower', '.txt']; 
                end
                if numSigBuffers == -6
                    saveToPathFile = [ saveToFullPath obj.fileWriteFilename obj.fileWriteFileNum '_temperature', '.txt'];
                end
                
                
                if exist(obj.fileWritePathname,'dir') ==0 %path does not exist?
                    mkdir(obj.fileWritePathname);
                end
                if exist(saveToFullPath,'dir') ==0 %path does not exist?
                    mkdir(saveToFullPath);
                end       

                fileIdentifier1 = fopen(saveToPathFile, 'a');
                fileIdentifier2 = -1;
            end
        end
    end
    
end

