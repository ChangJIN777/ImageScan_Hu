classdef EsrPulsedSweep < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       DAQ;
       srs;
       srs2;
       ESRControlFig;
       pulseBlaster;
       gesr;
       trackParameters;
       imageScanHandles;
       
          
       %image registration
       originalCursorX_um;
       originalCursorY_um;
       imageRegScanSize = 5;
       imageRegPointsPerLine = 50;
       imageRegDwellTime = 0.004;
       imageDataOriginalNVPL;
       imageDataCurrentNVPL;
       hImageRegNVPLFig=65423;
       
       % copy of the hardcoded volts/microns is here for convenience
       % 10/21/2014 - for UPLSAPO40X2 objective
       UMPerV = [143.67 136.973 10]; % x,y,z
       VPerUM = [0.006960395 0.007300709 0.1];
    end
    
    methods
        function obj = EsrPulsedSweep(handles,DAQ,PulseInterpret,SRS,gESR)
           
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
            obj.srs2 = handles.srs2;
            
        end
       
        function UpdateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
        
        function PTStruct = GetPulseTimeParametersFromGUI(obj, esrGUI)
            PTStruct = struct('p',str2num(get(esrGUI.piTime,'String')),...
                              'v',str2num(get(esrGUI.yPiTime,'String')),...
                              's',str2num(get(esrGUI.sampleWidth,'String')),...
                              'i',str2num(get(esrGUI.initTime,'String')),...
                              'a',str2num(get(esrGUI.delayTimeAOM,'String')),...
                              'r',str2num(get(esrGUI.readoutTime,'String')),...
                              'w',str2num(get(esrGUI.preReadoutWait,'String')),...
                              'u',str2num(get(esrGUI.depopulationTime,'String')),...
                              'y',str2num(get(esrGUI.tauEnd,'String')),...
                              'q',str2num(get(esrGUI.IQTime,'String')),... 
                              'b',str2num(get(esrGUI.delayTimeYellow,'String')),...
                              'c',str2num(get(esrGUI.delayTimeRed,'String')),...
                              'g',str2num(get(esrGUI.greenShelfTime,'String')),...
                              'h',str2num(get(esrGUI.redIonTime,'String')),...
                              'x',str2num(get(esrGUI.userVar2,'String')),...
                              'z',str2num(get(esrGUI.userVar3,'String')),...
                              'f',str2num(get(esrGUI.numLoops,'String')),...
                              'n',str2num(get(esrGUI.numLoops,'String')));
                          %more added by Dolev on 1/11/18
        end
        
        function durExpr = ReplacePulseVariables(obj, varInstr, currentLoopParameter,constStruct)
            % takes the 'duration' from the pulseblaster instruction
            % as variable 'varInstr' and replaces variables with values
            
            %if obj.loopSweep == 1
            %    durExpr = regexprep(varInstr,'t',num2str(obj.tau));
            %else
            durExpr = regexprep(varInstr,'t',num2str(currentLoopParameter));
            %end            
            durExpr = regexprep(durExpr,'p',num2str(constStruct.p));
            durExpr = regexprep(durExpr,'s',num2str(constStruct.s));
            durExpr = regexprep(durExpr,'i',num2str(constStruct.i));
            durExpr = regexprep(durExpr,'a',num2str(constStruct.a));
            durExpr = regexprep(durExpr,'r',num2str(constStruct.r));
            durExpr = regexprep(durExpr,'w',num2str(constStruct.w));
            durExpr = regexprep(durExpr,'u',num2str(constStruct.u));
            durExpr = regexprep(durExpr,'y',num2str(constStruct.y));
            durExpr = regexprep(durExpr,'q',num2str(constStruct.q));
            durExpr = regexprep(durExpr,'v',num2str(constStruct.v));
            durExpr = regexprep(durExpr,'b',num2str(constStruct.b));
            durExpr = regexprep(durExpr,'c',num2str(constStruct.c));
            durExpr = regexprep(durExpr,'g',num2str(constStruct.g));
            durExpr = regexprep(durExpr,'h',num2str(constStruct.h));            
            durExpr = regexprep(durExpr,'x',num2str(constStruct.x));
            durExpr = regexprep(durExpr,'z',num2str(constStruct.z)); 
            %more added by Dolev on 1/11/18
        end             
        
        function durExpr2 = ReplaceLoopVariables(obj, varInstr, currentLoopParameter)
            % takes the 'duration' from the pulseblaster instruction
            % as variable 'varInstr' and replaces variables with values
            %if obj.loopSweep == 1
            %    durExpr2 = regexprep(varInstr,'n',num2str(currentLoopParameter));
            %    durExpr2 = regexprep(durExpr2,'f',num2str(obj.loopNumberEnd));
            %else
               % durExpr2 = regexprep(varInstr,'n',num2str(constStruct.n));
                %durExpr2 = regexprep(durExpr2,'f',num2str(constStruct.n));
            durExpr2 = regexprep(varInstr,'n',num2str(currentLoopParameter));
            durExpr2 = regexprep(durExpr2,'f',num2str(0));
            %end
            
        end  
        
        function aomExpr = FlipAOMBitForNoInverter(obj, numInstr)
           
            if obj.imageScanHandles.configS.bHaveInverterBoard == 0
               % using regular inverter-on pulse sequences we
               % need to flip the first bit
               if numInstr == 0
                   
                   aomExpr = 14680065;
               elseif numInstr == 14680065
                   aomExpr = 0;
               end
            else
                % for inverter board in leave all the same
                aomExpr = numInstr;
            end
          aomExpr = numInstr;
        end
        
        function TestOutputSequence(obj, esrGUI)
           % same as PerformSequence except all this does is save the
           % reconciled and combined pulses loaded from the .esr file to a
           % single .txt file that can directly be read by the pulse
           % interpreter. All the variables will be set to the values given
           % in the GUI, and TAU (t) will just be set to its starting value
           
           INST_LONG_DELAY = 7;
           INST_CONTINUE = 0;
           INST_BRANCH = 6;
           INST_STOP = 1;
           MINPULSE = 10; % nanoseconds
           
           esrStructFilename = get(esrGUI.fileboxPulseSequence,'String');
            esrStruct = tdfread(esrStructFilename);
            [numBits, tempSize] = size(fieldnames(esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
            pulseStr = cell(numBits, 1);
            pulseNum = cell(numBits, 1);
            numInstructions = zeros(1,numBits);
            fieldnames(esrStruct)
            for nb = 1:numBits
                % load ESRPulse requires a full pathname to load from
                % in new code, make the .esr file not require full path
                % name but just get it from the pathname of the .esr file
                % itself
                pathESR = regexprep(esrStructFilename,'.esr','')
                %pathBitString = ['esrStruct.bit' num2str(nb)]
                pathBitString = [pathESR '_bit' num2str(nb) '.txt'];
                tempCell = obj.pulseBlaster.loadESRPulse(pathBitString);

                pulseStr{nb} = tempCell;
               % size( tempCell{1})
                [numInstructions(1,nb), ~] = size( tempCell{1});

                % prepare a numerical array for the instructions once eval'd
                pulseNum{nb} = zeros(numInstructions(1,nb),5);
            end
           
           pulseTimeStruct = obj.GetPulseTimeParametersFromGUI(esrGUI);
           %if obj.loopSweep == 1
           %     nowTauTime = obj.loopNumberStart;
           %else
                nowTauTime = str2num(get(esrGUI.tauStart,'String'));
           %end 
           %nowTauTime = obj.tauStart;
           
                    for mb = 1:numBits
                       for k = 1:numInstructions(1,mb)
                           tempCell = pulseStr{mb};
                           
                           aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k));
                           durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), nowTauTime, pulseTimeStruct); 
                           durExprSingle = durExpr{1};
                           durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), pulseTimeStruct.n); 
                           durExprSingle2 = durExpr2{1};

                           pulseNum{mb}(k,5) = eval(durExprSingle);
                           %pulseNum{mb}(k,4) = tempCell{1,4}(k);
                           pulseNum{mb}(k,4) = eval(durExprSingle2);
                           pulseNum{mb}(k,3) = tempCell{1,3}(k);
                           if mb == 1
                               if tempCell{1,2}(k) == 0
                                   pulseNum{mb}(k,2) = 14680065;
                               elseif tempCell{1,2}(k) == 14680065
                                   pulseNum{mb}(k,2) = 0;
                               end
                           else
                               pulseNum{mb}(k,2) = tempCell{1,2}(k);
                           end
                           pulseNum{mb}(k,1) = tempCell{1,1}(k);
                       end
                    end
                    
                    % next, must reconcile these sequences and change the
                    % stop command to a branch command
                    pulseSequenceString = [];
                    for nn = 1:numBits
                        if nn==numBits
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '}'];
                        else
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '},'];
                        end
                    end
                    

                    
%                     totalSequence = obj.pulseBlaster.reconcilePulses(pulseNumBit0,...
%                         pulseNumBit1, pulseNumBit2);
                    totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
                    [totalNumInstructions, ~] = size(totalSequence);

                    if totalSequence(totalNumInstructions,3) == INST_STOP
                        totalSequence(totalNumInstructions,3) = INST_BRANCH;
                    end
                    if totalSequence(totalNumInstructions,5) < MINPULSE
                        totalSequence(totalNumInstructions,5) = MINPULSE;
                        % in case combining the pulses somehow makes the
                        % last pulse duration = 0, which is not good
                    end
                    
                    %newsequence = totalSequence;
                    %newsequence(:,2) = str2double(dec2bin(newsequence(:,2)));
                    fprintf(1,'%i\t%8.0f\t%i\t%i\t%i\n',totalSequence')

           obj.pulseBlaster.setCurrentPulse(totalSequence);
           obj.pulseBlaster.loadToPulseblaster();
           obj.pulseBlaster.runPulse();
        end
        
        function StopTestSequence(obj)
           obj.pulseBlaster.stopPulse(); 
        end            
        
        function PerformSequence(obj,esrGUI)
            % update the file number to prevent saving over your data
            obj.gesr.UpdateFileNumber(esrGUI);
            
            % this new Perform sequence (replacing SweepControl...) will
            % now include all the combinations of # of counter
            % buffers/trigger channels and total signal traces.
            
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            inputAmpB = str2double(get(esrGUI.amplitudeB,'String'));
            if (inputAmp > 7) || (inputAmpB > 7)
                danger = questdlg('The amplitude is high for a pulsed measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop

                    case 'Run'
                        % continue on  
                end
            end 
            if get(esrGUI.checkboxRecordTemp,'Value')
                %instrreset;
                % commented out because we initialize in ImageScan now, like SRS gpib
                %lake = gpib('ni',0,12);
                %fopen(lake);

            end
            
           obj.imageScanHandles.bUseSRS2 =1; % got rid of srs2, don't want to restart matlab handles. 
           %Dolev Bluvstein -- Oct 27, 2018. Put in srs 2 again. Turned this from 0 to 1.
            
          'time setting'
          tic
            bUseSRS2 = obj.imageScanHandles.bUseSRS2;
          bUseSRS2=1;  %Dolev Bluvstein -- Oct 27, 2018. Put in srs 2 again. Turned this from 0 to 1.
            %obj.srs = gpib('ni', 0, 24);
            fclose(obj.srs);
            if bUseSRS2
               fclose(obj.srs2); 
            end
            
            %-----------------phase noise start code-------------------
            if get(esrGUI.checkboxUsePhaseNoiseModulation,'Value')  
                obj.gesr.setPhaseNoise(esrGUI,1); % turn on
            else
                if get(esrGUI.checkboxIQEnabled,'Value')
                    obj.gesr.IQmodulationON(1);
                else
                    obj.gesr.setPhaseNoise(esrGUI,0); % keep turned off
                end
            end
            if bUseSRS2
                if get(esrGUI.checkboxUsePhaseNoiseModulationB,'Value')  
                    obj.gesr.setPhaseNoiseB(esrGUI,1); % turn on
                    
                    % track a few times to make sure power doesn't drift NV
                     
                else
                    % 4/20/16 for now don't need any IQ code for SRS2
                   % if get(esrGUI.checkboxIQEnabled,'Value')
                   %     obj.gesr.IQmodulationON(1);
                   if get(esrGUI.checkboxIQEnabled,'Value')
                        obj.gesr.IQmodulationON(1);
                   else
                        obj.gesr.setPhaseNoise(esrGUI,0); % keep turned off
                   end
                end
            end
            %-----------------phase noise end code-------------------
            
            fopen(obj.srs);
                % Ntype selected
               fprintf(obj.srs, ['ENBL ', '0']);
                fprintf(obj.srs, ['ENBR ', '1']);
            fclose(obj.srs);
            
            if bUseSRS2
                fopen(obj.srs2);
                % Ntype selected
               fprintf(obj.srs2, ['ENBL ', '0']);
                fprintf(obj.srs2, ['ENBR ', '1']);
                fclose(obj.srs2);
            end
            
            obj.gesr.stopScan = false; %Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI); %disable the gui so the user cannot chnge parameters during a sweep
            obj.gesr.setAmp(esrGUI); %Set the amplitude for both SRS1 and 2
            obj.gesr.setFreq(esrGUI); %Set the frequency for both SRS1 and 2
             if bUseSRS2
               % pause(4)
                  %   obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles); 
                 %   obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles); 
                 %  obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
                   % obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
                  %  obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
             end
            
            set(esrGUI.numCompleted, 'String', num2str(0)); % reset this before starting new
            set(esrGUI.stepsSinceTracking, 'String', num2str(0)); % reset this before starting new
            
            % variables for determining when to track
            garbage = 1;
            refReady = 0;
            ref = 0;
            signal = 0;
            compteur = 0;
            
            if get(esrGUI.radio1Channel,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 1;
                numReadBuffersPerCounter = 4; %1/1 = 1
            elseif get(esrGUI.radio2Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 4; %2/2 = 1
            elseif get(esrGUI.radio4Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 4;
                numReadBuffersPerCounter = 8; %4/2 = 2
            elseif get(esrGUI.radio1Trig2Sig,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 8; %2/1 = 2
            end
            
            toc
            
            'time set up pulse'
            tic
            
            INST_LONG_DELAY = 7;
            INST_CONTINUE = 0;
            INST_BRANCH = 6;
            INST_STOP = 1;
            MINPULSE = 10; % nanoseconds, five 2 ns clock cycles of the PBlaster
            esrStructFilename = get(esrGUI.fileboxPulseSequence,'String');
            esrStruct = tdfread(esrStructFilename);
            [numBits, tempSize] = size(fieldnames(esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
            pulseStr = cell(numBits, 1);
            pulseNum = cell(numBits, 1);
            numInstructions = zeros(1,numBits);
            fieldnames(esrStruct)
            for nb = 1:numBits
                % load ESRPulse requires a full pathname to load from
                % in new code, make the .esr file not require full path
                % name but just get it from the pathname of the .esr file
                % itself. 
                pathESR = regexprep(esrStructFilename,'.esr','');
                %pathBitString = ['esrStruct.bit' num2str(nb)]
                pathBitString = [pathESR '_bit' num2str(nb) '.txt']
                tempCell = obj.pulseBlaster.loadESRPulse(pathBitString)

                pulseStr{nb} = tempCell
               % size( tempCell{1})
                [numInstructions(1,nb), ~] = size( tempCell{1});

                % prepare a numerical array for the instructions once eval'd
                pulseNum{nb} = zeros(numInstructions(1,nb),5);
            end
            
            % parameters from the ESR GUI
            tauStart = str2num(get(esrGUI.tauStart,'String'));
            tauEnd = str2num(get(esrGUI.tauEnd,'String'));
            numTauPoints = str2num(get(esrGUI.numTauPoints,'String'));
            numAverages = str2num(get(esrGUI.numAverages,'String'));
            repsPerTau = str2num(get(esrGUI.repsPerTau,'String'));
            listTauTime = linspace(tauStart,tauEnd,numTauPoints);
            
            %-------new 5/31/2013 to add in between tau points-----
            if get(esrGUI.checkboxUseExtraTauPoints,'Value')==1
                %CANNOT use str2double, only str2num works for this!
                listExtraTau = str2num(get(esrGUI.listExtraTauPoints,'String'));
                numTauPoints = numTauPoints+length(listExtraTau);
                listTauTime = [listTauTime listExtraTau];
                listTauTime = sort(listTauTime);
                
            end
            listTauTime = listTauTime';
            %------------------------------------------------------
            bPerShot = get(esrGUI.checkboxSaveDataPerShot,'Value');
            if bPerShot==true
                rawSignalList = zeros(length(listTauTime),repsPerTau);
                rawRefList = zeros(length(listTauTime),repsPerTau);
                rawSignalList2 = zeros(length(listTauTime),repsPerTau);
                rawRefList2 = zeros(length(listTauTime),repsPerTau);
            end
                rawSignalPlot = zeros(length(listTauTime),1);
                rawRefPlot = zeros(length(listTauTime),1);
                
                rawNormPlot = zeros(length(listTauTime),1);
                avgSignalPlot = zeros(length(listTauTime),1);
                avgRefPlot = zeros(length(listTauTime),1);
                totalNormPlot = zeros(length(listTauTime),1);
                if numSignalBuffers == 2
                    rawSignalPlot2 = zeros(length(listTauTime),1);
                    rawRefPlot2 = zeros(length(listTauTime),1);
                    
                    rawNormPlot2 = zeros(length(listTauTime),1);
                    avgSignalPlot2 = zeros(length(listTauTime),1);
                    avgRefPlot2 = zeros(length(listTauTime),1);
                    totalNormPlot2 = zeros(length(listTauTime),1);
                end
            thresholdXAxisUnits = 5000; % max obj.tauEnd to plot us or ns
            obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
            % readout initializations 
            %==================================================
            pulseTimeStruct = obj.GetPulseTimeParametersFromGUI(esrGUI);
            signalReadoutTime = pulseTimeStruct.r;
            refReadoutTime = pulseTimeStruct.r;
            if get(esrGUI.checkboxSignal50ns,'Value')==1
                signalReadoutTime = signalReadoutTime-50;
            end
            if get(esrGUI.checkboxReference50ns,'Value')==1
                refReadoutTime = refReadoutTime-50;
            end
            % don't use obj.NSamples, reserved for CW
            NPulseSamples = repsPerTau*numReadBuffersPerCounter+1; 
            obj.gesr.counterData = zeros(1,NPulseSamples);
            obj.gesr.counterData2 = zeros(1,NPulseSamples);
            obj.gesr.counterDataPerShot = zeros(1,NPulseSamples);
            %====================================================
            
            %====================
            % if it is a differential measurement there will be 't' and
            % 'y-t' durations. For the latter, y-t won't take on the same
            % time values as t unless t=0, which isn't general enough.
            % therefore after creating the list of tau times (done above)
            % change 'y' to make it 'y+taustart'
            if get(esrGUI.checkboxDifferentialMeasurement,'Value')==1
                pulseTimeStruct.y = pulseTimeStruct.y + tauStart;
            end
            % now 't' and 'y-t' will always range between the same times
            %======================
            
            %Computation of the tracking sequence
            %==============================================================
            % we use a on/off AOM sequence for tracking.
             esrTrackingStructFilename = [obj.imageScanHandles.configS.sequenceFolder 'TrackingAOMDutyCycle.esr'];
             esrTrackingStruct = tdfread(esrTrackingStructFilename);
             pathESR = regexprep(esrTrackingStructFilename,'.esr','');
             pathBitString = [pathESR '_bit' num2str(1) '.txt'];
             tempCell = obj.pulseBlaster.loadESRPulse(pathBitString);

             [numTrackingInstructions, dummy1] = size( tempCell{1});


             % prepare a numerical array for the instructions once eval'd
             pulseTrackingNum = zeros(numTrackingInstructions,5);
             for k = 1:numTrackingInstructions
                 
                aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), 0, pulseTimeStruct);
                durExprSingle = durExpr{1};
                durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), pulseTimeStruct.n); 
                durExprSingle2 = durExpr2{1};

                pulseTrackingNum(k,5) = eval(durExprSingle);
                pulseTrackingNum(k,4) = eval(durExprSingle2);
                pulseTrackingNum(k,3) = tempCell{1,3}(k);
                
                               if tempCell{1,2}(k) == 14680064
                                   pulseTrackingNum(k,2) = 14680065;
                               elseif tempCell{1,2}(k) == 14680065
                                   pulseTrackingNum(k,2) = 14680064;
                               end
                
                pulseTrackingNum(k,1) = tempCell{1,1}(k);
             end
             
                        
             clear tempCell;
            %==============================================================
            %added just to be able to initialize the AOM
            %==============================================================

             nowTauTime = pulseTimeStruct.s;

             for mb = 1:numBits
                 
                       for k = 1:numInstructions(1,mb)
                           tempCell = pulseStr{mb};
                           
                           aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                           durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), nowTauTime, pulseTimeStruct);
                           durExprSingle = durExpr{1};
                           durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), pulseTimeStruct.n); 
                           durExprSingle2 = durExpr2{1};

                           pulseNum{mb}(k,5) = eval(durExprSingle);
                           pulseNum{mb}(k,4) = eval(durExprSingle2);
                           pulseNum{mb}(k,3) = tempCell{1,3}(k);
                          if mb == 1
                               if tempCell{1,2}(k) == 0
                                   pulseNum{mb}(k,2) = 14680065;
                               elseif tempCell{1,2}(k) == 14680065
                                   pulseNum{mb}(k,2) = 0;
                               end
                           else
                               pulseNum{mb}(k,2) = tempCell{1,2}(k);
                           end
                           pulseNum{mb}(k,1) = tempCell{1,1}(k);
                           
                           clear tempCell;
                       end
              end
                    
                    % next, must reconcile these sequences and change the
                    % stop command to a branch command
                    pulseSequenceString = [];
                    for nn = 1:numBits
                        if nn==numBits
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '}'];
                        else
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '},'];
                        end
                    end
                    %pulseNum{1}(1,1)
                    totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
                    sizeConcatenatedSequences = size(pulseSequenceString);
                    clear pulseSequenceString; % we reinitialized this every loop so free the memory!
                    [totalNumInstructions, ~] = size(totalSequence);
                    if totalSequence(totalNumInstructions,3) == INST_STOP
                        totalSequence(totalNumInstructions,3) = INST_BRANCH;
                    end
                    if totalSequence(totalNumInstructions,5) < MINPULSE
                        totalSequence(totalNumInstructions,5) = MINPULSE;
                        % in case combining the pulses somehow makes the
                        % last pulse duration = 0, which is not good
                    end
                    totalSequence
            obj.pulseBlaster.setCurrentPulse(totalSequence);
            obj.pulseBlaster.loadToPulseblaster();
            obj.pulseBlaster.runPulse();
            pause(str2num(get(esrGUI.preMeasurePause,'String')));
            obj.pulseBlaster.stopPulse();
         %=================================================================                        
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            toc
           
            global storeLastSequenceCell
            bRunNormal=1;

            quantInterpXY8 = get(esrGUI.quantInterpXY8,'Value');
            
            if quantInterpXY8 == 1
               'Quantum Interpolation Called'
            end
            if bRunNormal==1
                %========================================================
                % new for 04-17-2014 (on Alice), new for 03/08/16 (on 1219 afm)
                %, preallocate all sequences of each tau, so
                % that time is not wasted redoing it on every sweep
                allSequencesCell = cell(1, length(listTauTime));
                for kTauTime = 1:length(listTauTime)
                    tic
                    nowTauTime = listTauTime(kTauTime); %pulseStr has the information encoded into it. Can expand it beforehand, then use the properly calculated delay to input the proper delays for each tau time.
                    %numInstructions would also have to change. This is
                    %just a row vector with the number of instructions per
                    %bit.. no big deal to change it.
                    
                    for mb = 1:numBits
                        tempCell = pulseStr{mb}; %added here and removed below so it doesn't remake it on every iteration. Dolev 1/10/2018
                        
                        if quantInterpXY8 == 1
                            [tempCell, numInstructions(1,mb)] = quantumInterpolationExpansion_compress(obj,tempCell,nowTauTime,pulseTimeStruct.n,pulseTimeStruct.y); %Quantum interpolation. Dolev 1/11/18
                        end
                        
                        
                        
                        %what we want to do now is add a button in the
                        %EsrGUI that gives the option for XY8-quantum
                        %interpolation. We will then have an if statement
                        %here that will expand tempcell appropriately, bit
                        %by bit, and leave it in the same format it was
                        %before (num, num, num, cell, cell)
                        for k = 1:numInstructions(1,mb)
                            %tempCell = pulseStr{mb} removed so that it
                            %doesn't make it again on every iteration.

                            aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k));
                            durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), nowTauTime, pulseTimeStruct);
                            durExprSingle = durExpr{1};
                            durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), pulseTimeStruct.n);
                            durExprSingle2 = durExpr2{1};

                            pulseNum{mb}(k,5) = eval(durExprSingle);
                            pulseNum{mb}(k,4) = eval(durExprSingle2);
                            pulseNum{mb}(k,3) = tempCell{1,3}(k);
                            if (mb == 1)  %&& obj.imageScanHandles.configS.bHaveInverterBoard==0)
                                if tempCell{1,2}(k) == 0
                                    pulseNum{mb}(k,2) = 14680065;
                                elseif tempCell{1,2}(k) == 14680065
                                    pulseNum{mb}(k,2) = 0;
                                end
                            else
                                pulseNum{mb}(k,2) = tempCell{1,2}(k);
                            end
                            pulseNum{mb}(k,1) = tempCell{1,1}(k);
                        end
                    end

                    % next, must reconcile these sequences and change the
                    % stop command to a branch command
                    pulseSequenceString = []; % reset the sequence string
                    for nn = 1:numBits
                        if nn==numBits
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '}'];
                        else
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '},'];
                        end
                    end
                    totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
                    [totalNumInstructions, ~] = size(totalSequence);
                    if totalSequence(totalNumInstructions,3) == INST_STOP
                        totalSequence(totalNumInstructions,3) = INST_BRANCH;
                    end
                    if totalSequence(totalNumInstructions,5) < MINPULSE
                        totalSequence(totalNumInstructions,5) = MINPULSE;
                        % in case combining the pulses somehow makes the
                        % last pulse duration = 0, which is not good
                    end

                    % finally, add this total sequence to the global cell array
                    % holding sequences of all the tau points.
                    allSequencesCell{1,kTauTime} = totalSequence;
                    [num2str(kTauTime) ' tau is done, here is sequence']
                    totalSequence
                    [num2str(kTauTime) ' sequence stored']
                    toc
                end
                
                storeLastSequenceCell = allSequencesCell;
                %============ end preallocation of sequences ==============
            else
                % if we just want to use past sequence:
                allSequencesCell = storeLastSequenceCell;
                'skipping store, using last sequences'
            end
           
            
            % START THE PULSE SEQUENCE, FOR EACH TAU DO THE FOLLOWING
            % 2) replace its operators and variables with one number
            % 3) now each is in pulseInterpreter form
            % 4) Use the Reconcile pulses () function to combine these
            jStart = str2num(get(esrGUI.plotAverageToStartAt,'String'));
            jPlot = jStart;
            jCounter = 1; % this counts up from 1 regardless of jStart
            set(esrGUI.numCompleted, 'String', num2str(jPlot-1));
            while jPlot <= numAverages && obj.gesr.stopScan == false
                jTauTime = 1;
                % we cut and paste the ClearTasks from here for tracking
                while jTauTime <= length(listTauTime) && obj.gesr.stopScan == false
                    nowTauTime = listTauTime(jTauTime);
                    
                    obj.DAQ.ClearTask('RunningCounter'); % if tracking
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    'time start measure while loop'
                    tic
                    
                    %03/08/16, removed pulse sequence setup here for
                    %pre-allocation
                    
                    %Initialization of the DAQ
                    %=====================================================
                    obj.DAQ.CreateTask('Counter2');
                    counterLine = 2;
                    obj.DAQ.ConfigureCounterIn('Counter2',counterLine,NPulseSamples);
                    obj.gesr.counterData = zeros(1,NPulseSamples); %obj.gesr.counterData = [];
                    
                    if (numSignalBuffers == 2)
                        if (numTriggers == 2)
                            obj.DAQ.CreateTask('Counter');
                            counterLine2 = 1;
                            obj.DAQ.ConfigureCounterIn('Counter',counterLine2,NPulseSamples);
                        end
                        obj.gesr.counterData2 = zeros(1,NPulseSamples); %obj.gesr.counterData2 = [];
                    end
                    
                    obj.DAQ.StartTask('Counter2');
                    if (numSignalBuffers == 2)
                        if (numTriggers==2)
                            obj.DAQ.StartTask('Counter');
                        end
                    end
                    pause(0.1);
                    %=====================================================
                    
                    obj.pulseBlaster.setCurrentPulse(allSequencesCell{1,jTauTime});
                    obj.pulseBlaster.loadToPulseblaster();
                    obj.pulseBlaster.runPulse();
                    
                    % function call which will keep updating getting counts
                    % while the pulseblaster in parallel is triggering the
                    % DAQ
                    obj.gesr.GetCountsUntilBuffersFilled(numTriggers);
                    
                    obj.gesr.counterData = diff(obj.gesr.counterData);
                    
                    if bPerShot==true
                        obj.gesr.counterDataPerShot = obj.gesr.counterData;
                        rawSignalList(jTauTime,:) = obj.gesr.counterData(1:numReadBuffersPerCounter:end);
                        rawRefList(jTauTime,:) = obj.gesr.counterData(3:numReadBuffersPerCounter:end);
                    end
                    'green';
                    obj.gesr.counterData(1:numReadBuffersPerCounter:end);
                    'yellow';
                    obj.gesr.counterData(3:numReadBuffersPerCounter:end);
                   
                    
                    signalPoint = sum(obj.gesr.counterData(1:numReadBuffersPerCounter:end))/(repsPerTau*(signalReadoutTime)*1e-6)
                    (obj.gesr.counterData(1:numReadBuffersPerCounter:end))/(repsPerTau*(signalReadoutTime)*1e-6);
                    %signalPoint_err = std((obj.gesr.counterData(1:numReadBuffersPerCounter:end))/(1*(signalReadoutTime)*1e-6))
                    refPoint = sum(obj.gesr.counterData(3:numReadBuffersPerCounter:end))/(repsPerTau*(refReadoutTime)*1e-6);
                    rawSignalPlot(jTauTime,1) = signalPoint;
                    rawRefPlot(jTauTime,1) = refPoint;
                    
                    obj.DAQ.StopTask('Counter2');
                    obj.DAQ.ClearTask('Counter2');
                    if (numSignalBuffers == 2)
                        if (numTriggers == 2)
                            obj.gesr.counterData2 = diff(obj.gesr.counterData2);
                            signalPoint2 = sum(obj.gesr.counterData2(1:numReadBuffersPerCounter:end))/(repsPerTau*(signalReadoutTime)*1e-6);
                            refPoint2 = sum(obj.gesr.counterData2(3:numReadBuffersPerCounter:end))/(repsPerTau*(refReadoutTime)*1e-6);
                            rawSignalPlot2(jTauTime,1) = signalPoint2;
                            rawRefPlot2(jTauTime,1) = refPoint2;

                            obj.DAQ.StopTask('Counter');
                            obj.DAQ.ClearTask('Counter');
                        elseif (numTriggers == 1)
                            
                            if bPerShot==true
                                rawSignalList2(jTauTime,:) = obj.gesr.counterData(5:numReadBuffersPerCounter:end);
                                rawRefList2(jTauTime,:) = obj.gesr.counterData(7:numReadBuffersPerCounter:end);
                            end
                            signalPoint2 = sum(obj.gesr.counterData(5:numReadBuffersPerCounter:end))/(repsPerTau*(signalReadoutTime)*1e-6);
                            refPoint2 = sum(obj.gesr.counterData(7:numReadBuffersPerCounter:end))/(repsPerTau*(refReadoutTime)*1e-6);
                            rawSignalPlot2(jTauTime,1) = signalPoint2;
                            rawRefPlot2(jTauTime,1) = refPoint2;
                        end
                    end
                    
                   % signalPoint-signalPoint2
                    %refPoint-refPoint2
                    toc
                    if obj.gesr.stopScan
                        break; % made sure to have this AFTER stopTask on DAQ.
                    end
                    % plot(obj.currentAxes, listTauTime, obj.counterData, 'Color','b');
                    % scale the units of the x axis depending on maximum tau
                    
                    singleTime =[nowTauTime; nowTauTime];
                    if tauEnd > thresholdXAxisUnits
                         tempXTau = listTauTime*10^-3;
                         singleTime = singleTime*10^-3;
                    else
                         tempXTau = listTauTime;
                    end

                    maxPlot = max(rawRefPlot);
                    minPlot = min(rawSignalPlot);
                    
                    if (numSignalBuffers ==1 )
 
                            plot(currentAxes,...
                                 tempXTau,rawRefPlot(:,1),'b',...
                                 tempXTau,rawSignalPlot(:,1),'m',...
                                 tempXTau,avgRefPlot,'g',...
                                 tempXTau,avgSignalPlot,'k',...
                                 singleTime,[minPlot,maxPlot],'r--');
                            title(currentAxes, 'Raw Data');
                            legend(currentAxes, 'New reference','New signal',...
                                 'Average reference','Average signal', 'Location','South');
                    elseif (numSignalBuffers == 2)
                        plot(currentAxes,...
                        tempXTau,rawRefPlot(:,1),'b',...
                        tempXTau,rawSignalPlot(:,1),'m',...
                        tempXTau,avgRefPlot,'c--',...
                        tempXTau,avgSignalPlot,'k--',...
                        tempXTau,rawRefPlot2(:,1),'r',...
                        tempXTau,rawSignalPlot2(:,1),'g',...
                        tempXTau,avgRefPlot2,'c-',... %need other color
                        tempXTau,avgSignalPlot2,'k-',...
                        singleTime,[minPlot,maxPlot],'r--'); %need other colors
                    
                        title(currentAxes, 'Raw Data');
                    
                        legend(currentAxes, 'New reference1','New signal1',...
                            'Average reference1','Average signal1','New reference2','New signal2',...
                            'Average reference2','Average signal2', 'Location','South');
                    end

                     
                    if tauEnd > thresholdXAxisUnits
                         xlabel(currentAxes,'\tau (microseconds)');
                    else
                         xlabel(currentAxes,'\tau (nanoseconds)');
                    end       
                    ylabel(currentAxes,'PL (kCounts/s)');
                    jTauTime = jTauTime + 1;
                    
                    obj.pulseBlaster.stopPulse(); % done with current Tau sequence
                    
                    %######################  Tracking #######################################
                    totalTauCounter = str2num(get(esrGUI.numCompleted,'String'))*length(listTauTime)+jTauTime;
                    
                    compteur = compteur + 1;
                    if get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
                        
                        %Added 04/24/14 to change pulse sequence tracking
                        %to be every fixed number of steps instead of
                        %looking at the PL
                        tempTSteps = str2num(get(esrGUI.stepsSinceTracking, 'String'));
                        
                        
                        if tempTSteps >= str2num(get(esrGUI.pulseTrackingPeriod, 'String'))
                             %initialisation of the AOM for tracking
                                    obj.pulseBlaster.setCurrentPulse( pulseTrackingNum);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String'))); 
                                    
                                    obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
                                    
                                    if get(esrGUI.checkboxUseImageRegistration,'Value')
                                        obj.PerformImageRegistration(0,0);
                                    end
                        
                                    set(esrGUI.stepsSinceTracking, 'String', num2str(0));
                        
                                    %added here on 05/11/2012 to re-initialize the AOM
                                    %before starting a new measurement
                                    %==================================================
                                    
                                    % temperature and anglog input for
                                    % laser power
                                    %------------------------------------
                                    if get(esrGUI.checkboxRecordTemp,'Value')
                                        % record the temperature at this same time as surface reading
                                        fopen(lake);
                                        fprintf(lake,'KRDG?A');
                                        response = fscanf(lake);
                                        tempA = str2double(response);
                                        fprintf(lake,'KRDG?B');
                                        response = fscanf(lake);
                                        fclose(lake);
                                        tempB = str2double(response);
                                        cl = clock;
                                        [fida,fidb] = obj.gesr.DefineESRDataSavePath(esrGUI,-6);
                                        fprintf(fida, '%e\t%e\t%e\t%e\t%e\t%e\t%e\t%e\n', [cl,tempA,tempB]);
                                        fclose(fida);
                                        clear fida
                                    end
                                    if get(esrGUI.checkboxRecordLaser,'Value')
                                        
                                        % turn the aom on while doing the
                                        % laser power measurement (after
                                        % fiber output)
                                        obj.pulseBlaster.stopPulse();
                                        obj.pulseBlaster.setCurrentPulse( 'bit1_on.txt');
                                        obj.pulseBlaster.loadToPulseblaster();
                                        obj.pulseBlaster.runPulse();
                                        pause(1);
                                        
                                        obj.DAQ.CreateTask('SampleClock');
                                        clockFrequency = 10^4;
                                        clockLine = 1;
                                        obj.DAQ.ConfigureClockOut('SampleClock', clockLine,clockFrequency,0.5);
                                        obj.DAQ.CreateTask('VoltageInLaser');
                                       %---
                                       aiLine = 1;
                                       NSamples = 10000;
                                       %---
                                       obj.DAQ.ConfigureVoltageIn('VoltageInLaser',aiLine,NSamples,DAQManager.CLK1);
                                       obj.DAQ.StartTask('SampleClock');
                                       obj.DAQ.StartTask('VoltageInLaser');
                                       
                                       while (obj.DAQ.IsTaskDone('VoltageInLaser') == false) 
                                           pause(0.1);
                                       end
                                       obj.DAQ.StopTask('SampleClock');
                                       NSamplesAvailable = obj.DAQ.GetAvailableSamples('VoltageInLaser');
                                       meterVoltageArray = obj.DAQ.ReadVoltageIn('VoltageInLaser',NSamplesAvailable);
                                       meterVoltage = mean(meterVoltageArray)
                                       meterPower = (meterVoltage/2) * str2double(get(esrGUI.laserMeterRange,'String'))% convert range of 2 volts to power
                                       cl = clock;
                                       [fida,fidb] = obj.gesr.DefineESRDataSavePath(esrGUI,-5);
                                        
                                        fprintf(fida, '%e\t%e\t%e\t%e\t%e\t%e\t%e\t%e\n', [cl,meterVoltage, meterPower]);
                                        fclose(fida);
                                        clear fida
                                    end
                                    %---------------------------------------
                                    
                                    obj.pulseBlaster.stopPulse();
                                    obj.pulseBlaster.setCurrentPulse(totalSequence);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String')));
                                    obj.pulseBlaster.stopPulse();
                        else
                             
                             set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));     
                        end
                    end
                       
                    %################### Tracking done ########################## 
                    
                end % end loop through Tau points
                
                % update the normalized and averaged plots
                rawNormPlot(:,1) = rawSignalPlot(:,1)./rawRefPlot(:,1);
                avgSignalPlot = (avgSignalPlot.*(jCounter-1)+rawSignalPlot(:,1) )/jCounter;
                avgRefPlot = (avgRefPlot.*(jCounter-1)+rawRefPlot(:,1) )/jCounter;
                totalNormPlot = ( totalNormPlot*(jCounter-1) + rawNormPlot(:,1))/jCounter;
                        signalCounts = rawSignalPlot(:,1)+(jCounter-1).*avgSignalPlot;
                        signalCounts = signalCounts*repsPerTau*(signalReadoutTime)*1e-9*1000; % kCounts/s -> Counts
                        refCounts = rawRefPlot(:,1)+(jCounter-1).*avgRefPlot;
                        refCounts = refCounts*repsPerTau*(signalReadoutTime)*1e-9*1000; % kCounts/s -> Counts
                        diffSigCounts = signalCounts-refCounts;
                if (numSignalBuffers == 2)
                    rawNormPlot2(:,1) = rawSignalPlot2(:,1)./rawRefPlot2(:,1);
                    avgSignalPlot2 = (avgSignalPlot2.*(jCounter-1)+rawSignalPlot2(:,1) )/jCounter;
                    avgRefPlot2 = (avgRefPlot2.*(jCounter-1)+rawRefPlot2(:,1) )/jCounter;
                    totalNormPlot2 = ( totalNormPlot2*(jCounter-1) + rawNormPlot2(:,1))/jCounter;
                        signalCounts2 = rawSignalPlot2(:,1)+(jCounter-1).*avgSignalPlot2;
                        signalCounts2 = signalCounts2*repsPerTau*(signalReadoutTime)*1e-9*1000; % kCounts/s -> Counts
                        refCounts2 = rawRefPlot2(:,1)+(jCounter-1).*avgRefPlot2;
                        refCounts2 = refCounts2*repsPerTau*(signalReadoutTime)*1e-9*1000; % kCounts/s -> Counts
                        diffSigCounts2=signalCounts2-refCounts2;
                end
                
                if tauEnd > thresholdXAxisUnits
                    tempXTau = listTauTime*10^-3;
                else
                    tempXTau = listTauTime;
                end
                
                if (numSignalBuffers == 1)
                    if get(esrGUI.checkboxShowTotalCounts,'Value')==1

%                         plot(averageAxes,tempXTau,signalCounts,'r--',...
%                            tempXTau,refCounts,'r-.', ...
%                             tempXTau,signalCounts-refCounts,'r-');
                        
                        shotSignal = sqrt(signalCounts);
                        shotRef = sqrt(refCounts);
                        shotDiff = sqrt(shotSignal.^2 + shotRef.^2);
                        errorbar(averageAxes,tempXTau,diffSigCounts,shotDiff,'r-');
                        legend(currentAxes, 'Signal counts','Reference counts','Signal-Reference counts','Location','South');
                        ylabel(averageAxes,'PL (Total photon counts)');
                        title(averageAxes,'Difference in total photon counts');
                        
                    else
                        plot(averageAxes,tempXTau,totalNormPlot,'r');
                        ylabel(averageAxes,'PL (sig)/ref');
                        title(averageAxes, 'normalized to reference after each sweep, sweeps averaged');
                    end
                elseif (numSignalBuffers == 2)
                    if get(esrGUI.checkboxShowTotalCounts,'Value')==1
%                         plot(averageAxes,tempXTau,signalCounts,'r-',...
%                             tempXTua,refCounts,'r-.',...
%                             tempXTau,signalCounts2,'b-',...
%                             tempXTau,refCounts2,'b-.');
                        shotSignal = sqrt(signalCounts);
                        shotRef = sqrt(refCounts);
                        shotDiff = sqrt(shotSignal.^2 + shotRef.^2);
                        shotSignal2 = sqrt(signalCounts2);
                        shotRef2 = sqrt(refCounts2);
                        shotDiff2 = sqrt(shotSignal2.^2 + shotRef2.^2);
                        plot(averageAxes,tempXTau,diffSigCounts,'r-',tempXTau,diffSigCounts-shotDiff,'r:',tempXTau,diffSigCounts+shotDiff,'r:',...
                            tempXTau,diffSigCounts2,'b-',tempXTau,diffSigCounts2-shotDiff2,'b:',tempXTau,diffSigCounts2+shotDiff2,'b:');

                        title(averageAxes,'Difference in total photon counts');
                              ylabel(averageAxes,'PL (Total counts)');
                        legend(currentAxes, 'Signal1 counts','reference1 counts','Signal2 counts','reference2 counts','Location','South');
                        title(averageAxes,'Difference in total photon counts');
                    else
                        plot(averageAxes,tempXTau,totalNormPlot,'r',...
                        tempXTau,totalNormPlot2,'b');
                        legend(currentAxes, 'Norm trace 1','Norm trace 2','Location','South');
                        ylabel(averageAxes,'PL (sig)/ref');
                        title(averageAxes, 'normalized to reference after each sweep, sweeps averaged');
                    end
                end
                if tauEnd > thresholdXAxisUnits
                    xlabel(averageAxes,'\tau (microseconds)');
                else
                    xlabel(averageAxes,'\tau (nanoseconds)');
                end
                
               
                %%%%%%Write the data to a file if we are supposed to on this
                %step
                % do not save the data if we have stopped in the middle of
                % taking tau points, since the file will have useless NANs
                if ( mod(jPlot, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
                    
                    [fida,fidb] = obj.gesr.DefineESRDataSavePath(esrGUI,numSignalBuffers);
                    fprintf(fida, '%s\t%s\t%s\t%s\n', '2Tau','rawSignal','rawRef','totalNorm');
                    fprintf(fida, '%e\t%e\t%e\t%e\n', [2*listTauTime'; rawSignalPlot(:,1)'; rawRefPlot(:,1)'; totalNormPlot']);
                    fclose(fida);
                    clear fida
                    
                    if (numSignalBuffers==2)
                        fprintf(fidb, '%s\t%s\t%s\t%s\n', '2Tau','rawSignal','rawRef','totalNorm');
                        fprintf(fidb, '%e\t%e\t%e\t%e\n', [2*listTauTime'; rawSignalPlot2(:,1)'; rawRefPlot2(:,1)'; totalNormPlot2']);
                        fclose(fidb);
                        clear fidb
                    end
                    
                    if (bPerShot)
                        % write the large matrices for the per-shot counts
                        saveToFullPath = [obj.gesr.fileWritePathname obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '\'];
                        fname_a = [ saveToFullPath obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '_Scnt_1_' get(esrGUI.numCompleted,'String') '.txt'];
                        fname_b = [ saveToFullPath obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '_Scnt_2_' get(esrGUI.numCompleted,'String') '.txt'];
                        fname_c = [ saveToFullPath obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '_Rcnt_1_' get(esrGUI.numCompleted,'String') '.txt'];
                        fname_d = [ saveToFullPath obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '_Rcnt_2_' get(esrGUI.numCompleted,'String') '.txt'];
                            dlmwrite(fname_a,int16(rawSignalList),'\t');
                            dlmwrite(fname_b,int16(rawSignalList2),'\t');
                            dlmwrite(fname_c,int16(rawRefList),'\t');
                            dlmwrite(fname_d,int16(rawRefList2),'\t');
                    end
                    
                    if jCounter == 1
                        %Saving Metadata - added by Cole Williams 11/17/2018
                        PTMetadataSet = struct2dataset(pulseTimeStruct); %retrieves from struct made by GUI
                        %gets values from other boxes in GUI piece by piece
                        try
                            DMMdataCheck = get(esrGUI.checkboxDifferentialMeasurement,'Value');
                        catch
                            warning('No Differential Measurement Checkbox - assigning value N/A');
                            DMMdataCheck = 'N/A';
                        end
                        DiffMeasMDataStruct = struct('Differential_Measurement_Check', DMMdataCheck);

                        try
                            NumPlotSweepsMData = get(esrGUI.numAverages,'String');
                        catch
                            warning('Number of Sweeps not found - assigning value N/A');
                            NumPlotSweepsMData = 'N/A';
                        end
                        NumPlotSweepsMDataStruct = struct('Number_of_Sweeps', NumPlotSweepsMData);

                        try
                            CenterRF1MData = get(esrGUI.centerFreq,'String');
                        catch
                            warning('Center RF 1 not found - assigning value N/A');
                            CenterRF1MData = 'N/A';
                        end
                        try
                            RFAmplitude1MData = get(esrGUI.amplitude,'String');
                        catch
                            warning('Amplitude 1 not found - assigning value N/A');
                            RFAmplitude1MData = 'N/A';
                        end
                        try
                           CenterRF2MData =  get(esrGUI.centerFreqB,'String');
                        catch
                            warning('Center RF 2 not found - assigning value N/A');
                            CenterRF2MData = 'N/A';
                        end
                        try
                            RFAmplitude2MData = get(esrGUI.amplitudeB,'String');
                        catch
                            warning('Amplitude 2 not found - assigning value N/A');
                            RFAmplitude2MData = 'N/A';
                        end
                        RFMDataStruct = struct('Center_RF_1',CenterRF1MData,...
                            'RF_Amplitude_1',RFAmplitude1MData,...
                            'Center_RF_2', CenterRF2MData,...
                            'RF_Amplitude_2', RFAmplitude2MData);

                        try
                            IQMData = get(esrGUI.checkboxIQEnabled,'Value');
                        catch
                            warning('IQ Modulation Checkbox not found - assigning value N/A');
                            IQMData = 'N/A';
                        end
                        IQMDataStruct = struct('IQ_Modulation', IQMData);

                        try
                            XY8MData = get(esrGUI.quantInterpXY8,'Value');
                        catch
                            warning('XY8 checkbox not found - assigning value N/A');
                            XY8MData = 'N/A';
                        end
                        XY8MDataStruct = struct('XY8_Quantum_Interpolation', XY8MData);
                        Metadata = cat(2,PTMetadataSet,struct2dataset(DiffMeasMDataStruct),...
                            struct2dataset(NumPlotSweepsMDataStruct),struct2dataset(RFMDataStruct),...
                            struct2dataset(IQMDataStruct),struct2dataset(XY8MDataStruct));

                        %writes table to same place as data, called Metadata.txt
                        saveToFullPath = [obj.gesr.fileWritePathname obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '\'];
                        MDfilename = [ saveToFullPath obj.gesr.fileWriteFilename obj.gesr.fileWriteFileNum '_Metadata.txt'];
                        export(Metadata,'file',MDfilename,'Delimiter','\t');
                        'Metadata saved'
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                jPlot = jPlot + 1;
                jCounter=jCounter+1;
                % numCompleted must be kept as jPlot to do the saving
                % correctly
                set(esrGUI.numCompleted, 'String', num2str(jPlot-1)); 
                obj.pulseBlaster.stopPulse(); % stop the pulse sequence if tracking
                
             end % end loop through specified number of total plot averages
             
             % after the sequence is finished for all averages
            obj.pulseBlaster.stopPulse(); % just in case still running
            if obj.imageScanHandles.configS.bHaveInverterBoard==0
                % no inverter board so by default have laser back on
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                obj.pulseBlaster.loadToPulseblaster();
                obj.pulseBlaster.runPulse();
            end
            %cleanup lakeshore 331
            if get(esrGUI.checkboxRecordTemp,'Value')
                %fclose(lake);
                %delete(lake)
            end
            fopen(obj.srs);
            fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
            fclose(obj.srs);
            if obj.imageScanHandles.bUseSRS2
                fopen(obj.srs2);
                fprintf(obj.srs2, ['ENBR ', '0']); % turn off the N RF output
                fclose(obj.srs2);
            end
            
            if ~get(esrGUI.checkboxIQEnabled,'Value')
                    obj.gesr.setPhaseNoise(esrGUI,0); % turn off at end
            end
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
            
            % for AFM calls, this '0' signals measurement is complete
            set(esrGUI.writeDataFreq,'UserData',0); 
        end
        
        function PerformPulsedESRSequence(obj, esrGUI)
            obj.gesr.UpdateFileNumber(esrGUI);
            global Scan_Finished_Flag
            Scan_Finished_Flag = 0;
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            inputAmpB = str2double(get(esrGUI.amplitudeB,'String'));
            if (inputAmp > -5) || (inputAmpB > -5)
                danger = questdlg('The amplitude is high for a pulsed esr measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop

                    case 'Run'
                        % continue on  
                end
            end
            
            
          obj.imageScanHandles.bUseSRS2 =1; % got rid of srs2, don't want to restart matlab handles. 
           %Dolev Bluvstein -- Oct 27, 2018. Put in srs 2 again. Turned this from 0 to 1.

          bUseSRS2 = obj.imageScanHandles.bUseSRS2;
          bUseSRS2=1;  %Dolev Bluvstein -- Oct 27, 2018. Put in srs 2 again. Turned this from 0 to 1.
            %obj.srs = gpib('ni', 0, 24);
            
            useSRS2inPESR = get(esrGUI.useSRS2inPESR,'Value'); %Dolev Nov. 1-added to sweep frequency of SRS2.
            
            if bUseSRS2 == 1
                fclose(obj.srs2);
                fopen(obj.srs2);
                    % Ntype selected
                    fprintf(obj.srs2, ['ENBL ', '0']);
                    fprintf(obj.srs2, ['ENBR ', '1']);
                fclose(obj.srs2);
            end
                fclose(obj.srs);
                fopen(obj.srs);
                    % Ntype selected
                    fprintf(obj.srs, ['ENBL ', '0']);
                    fprintf(obj.srs, ['ENBR ', '1']);
                fclose(obj.srs);
            
            obj.gesr.stopScan = false; %Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI); %disable the gui so the user cannot chnge parameters during a sweep
            obj.gesr.setAmp(esrGUI); %Set the amplitude
            obj.gesr.setFreq(esrGUI);
            set(esrGUI.numCompleted, 'String', num2str(0)); % reset this before starting new
            set(esrGUI.stepsSinceTracking, 'String', num2str(0)); % reset this before starting new
            
            % variables for determining when to track
            garbage = 1;
            refReady = 0;
            ref = 0;
            signal = 0;
            compteur = 0;
            
            INST_LONG_DELAY = 7;
            INST_CONTINUE = 0;
            INST_BRANCH = 6;
            INST_STOP = 1;
            MINPULSE = 10; % nanoseconds, five 2 ns clock cycles of the PBlaster
            esrStructFilename = get(esrGUI.fileboxPulseSequence,'String');
            esrStruct = tdfread(esrStructFilename);
            [numBits, tempSize] = size(fieldnames(esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
            pulseStr = cell(numBits, 1);
            pulseNum = cell(numBits, 1);
            numInstructions = zeros(1,numBits);
            fieldnames(esrStruct)
            for nb = 1:numBits
                % load ESRPulse requires a full pathname to load from
                % in new code, make the .esr file not require full path
                % name but just get it from the pathname of the .esr file
                % itself. 
                pathESR = regexprep(esrStructFilename,'.esr','');
                %pathBitString = ['esrStruct.bit' num2str(nb)]
                pathBitString = [pathESR '_bit' num2str(nb) '.txt'];
                tempCell = obj.pulseBlaster.loadESRPulse(pathBitString);

                pulseStr{nb} = tempCell;
               % size( tempCell{1})
                [numInstructions(1,nb), ~] = size( tempCell{1});

                % prepare a numerical array for the instructions once eval'd
                pulseNum{nb} = zeros(numInstructions(1,nb),5);
            end
            
            if get(esrGUI.useSRS2inPESR,'Value') == 1
                centerFreq = str2num(get(esrGUI.centerFreqB, 'String'));
            else
                centerFreq = str2num(get(esrGUI.centerFreq, 'String'));
            end
            
            numFreqSteps = str2num(get(esrGUI.numPulseFreqPoints, 'String'));
            numAverages = str2num(get(esrGUI.numAverages, 'String'));
            repsPerFreqPoint = str2num(get(esrGUI.repsPerFreqPoint,'String'));
            freqdev = str2num(get(esrGUI.pulseFreqDeviation, 'String'));
            freqSweepRange = centerFreq + freqdev*[-1 1]; % set freq range
            
            listFreq = linspace(freqSweepRange(1), freqSweepRange(2), numFreqSteps)';
            
            numSignalBuffers = 1;
            numTriggers = 1;
            rawSignalPlot = zeros(length(listFreq),1);
            rawRefPlot = zeros(length(listFreq),1);
            rawNormPlot = zeros(length(listFreq),1);
            avgSignalPlot = zeros(length(listFreq),1);
            avgRefPlot = zeros(length(listFreq),1);
            totalNormPlot = zeros(length(listFreq),1);
            obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            
            %++++++++++++++++++++++++++
            pulseTimeStruct = obj.GetPulseTimeParametersFromGUI(esrGUI);
            signalReadoutTime = pulseTimeStruct.r;
            refReadoutTime = pulseTimeStruct.r;
            if get(esrGUI.checkboxSignal50ns,'Value')==1
                signalReadoutTime = signalReadoutTime-50;
            end
            if get(esrGUI.checkboxReference50ns,'Value')==1
                refReadoutTime = refReadoutTime-50;
            end
            
            if get(esrGUI.radio1Channel,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 1;
                numReadBuffersPerCounter = 4; %1/1 = 1
            elseif get(esrGUI.radio2Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 4; %2/2 = 1
            elseif get(esrGUI.radio4Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 4;
                numReadBuffersPerCounter = 8; %4/2 = 2
            elseif get(esrGUI.radio1Trig2Sig,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 8; %2/1 = 2
            end
            NPulseSamples = repsPerFreqPoint*numReadBuffersPerCounter+1; % don't use obj.NSamples, reserved for CW
            obj.gesr.counterData = zeros(1,NPulseSamples);
            obj.gesr.counterData2 = zeros(1,NPulseSamples);
            %+++++++++++++++++++++++++++++
            
            %Computation of the tracking sequence
            %==============================================================
            % we use a on/off AOM sequence for tracking.
             esrTrackingStruct = tdfread([obj.imageScanHandles.configS.sequenceFolder 'TrackingAOMDutyCycle.esr']);
             tempCell = obj.pulseBlaster.loadESRPulse(eval(['esrTrackingStruct.bit' num2str(1)]));

             [numTrackingInstructions, ~] = size( tempCell{1});

             % prepare a numerical array for the instructions once eval'd
             pulseTrackingNum = zeros(numTrackingInstructions,5);
             for k = 1:numTrackingInstructions
                 
                aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), 0, pulseTimeStruct); 
                durExprSingle = durExpr{1};
                durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), 0); 
                durExprSingle2 = durExpr2{1};

                pulseTrackingNum(k,5) = eval(durExprSingle);
                pulseTrackingNum(k,4) = eval(durExprSingle2);
                pulseTrackingNum(k,3) = tempCell{1,3}(k);
                pulseTrackingNum(k,2) = aomExpr;%tempCell{1,2}(k);
                pulseTrackingNum(k,1) = tempCell{1,1}(k);
             end
                        
             clear tempCell;
            %==============================================================
            
            %Open the RF generator and initialize a list of SG states
            1
            if useSRS2inPESR == 1
                fopen(obj.srs2);
                fprintf(obj.srs2, ['LSTC? ', num2str(length(listFreq))]); % create a list of SG states
                fprintf(obj.srs2, '*CLS');
                listFreq = listFreq*(10^6); % change to Hz units
                for i = 1:length(listFreq)
                       % pre-load each state of the list into the SG384 memory
                       fprintf(obj.srs2, ['LSTP ',num2str(i-1),',',num2str(listFreq(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
                end
                % enable the list
                fprintf(obj.srs2,'LSTE 1');  % 1 or 0 for enabled or disabled  
            else
                fopen(obj.srs);
                fprintf(obj.srs, ['LSTC? ', num2str(length(listFreq))]); % create a list of SG states
                fprintf(obj.srs, '*CLS');
                listFreq = listFreq*(10^6); % change to Hz units
                for i = 1:length(listFreq)
                       % pre-load each state of the list into the SG384 memory
                       fprintf(obj.srs, ['LSTP ',num2str(i-1),',',num2str(listFreq(i)),',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
                end
                % enable the list
                fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled            
            end
            %==============================================================
            %added just to be able to initialize the AOM
            %==============================================================

             nowTauTime = pulseTimeStruct.s;
            
             for mb = 1:numBits
                       for k = 1:numInstructions(1,mb)
                           tempCell = pulseStr{mb};
                           
                           aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                           durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), nowTauTime, pulseTimeStruct); 
                           durExprSingle = durExpr{1};
                           durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), nowTauTime); 
                           durExprSingle2 = durExpr2{1};

                           pulseNum{mb}(k,5) = eval(durExprSingle);
                           pulseNum{mb}(k,4) = eval(durExprSingle2);
                           pulseNum{mb}(k,3) = tempCell{1,3}(k);
                            if mb == 1
                               if tempCell{1,2}(k) == 0
                                   pulseNum{mb}(k,2) = 14680065;
                               elseif tempCell{1,2}(k) == 14680065
                                   pulseNum{mb}(k,2) = 0;
                               end
                           else
                               pulseNum{mb}(k,2) = tempCell{1,2}(k);
                           end
                           pulseNum{mb}(k,1) = tempCell{1,1}(k);
                           
                           clear tempCell;
                       end
              end
                    
                    % next, must reconcile these sequences and change the
                    % stop command to a branch command
                    pulseSequenceString = [];
                    for nn = 1:numBits
                        if nn==numBits
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '}'];
                        else
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '},'];
                        end
                    end
                    totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
                    sizeConcatenatedSequences = size(pulseSequenceString);
                    clear pulseSequenceString; % we reinitialized this every loop so free the memory!
                    [totalNumInstructions, ~] = size(totalSequence);
                    if totalSequence(totalNumInstructions,3) == INST_STOP
                        totalSequence(totalNumInstructions,3) = INST_BRANCH;
                    end
                    if totalSequence(totalNumInstructions,5) < MINPULSE
                        totalSequence(totalNumInstructions,5) = MINPULSE;
                        % in case combining the pulses somehow makes the
                        % last pulse duration = 0, which is not good
                    end
            totalSequence        
            obj.pulseBlaster.setCurrentPulse(totalSequence);
            obj.pulseBlaster.loadToPulseblaster();
            obj.pulseBlaster.runPulse();
            pause(str2num(get(esrGUI.preMeasurePause,'String')));
            %=================================================================                        
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            
            jPlot = 1;
            
            
            while jPlot <= numAverages && obj.gesr.stopScan == false
                jFreqStep = 1;
                % we cut and paste the ClearTasks from here for tracking
                while jFreqStep <= length(listFreq) && obj.gesr.stopScan == false
                    
                    if useSRS2inPESR == 1
                        fprintf(obj.srs2, '*TRG'); % trigger the list to next frequency
                    else
                        fprintf(obj.srs, '*TRG'); % trigger the list to next frequency
                    end
                    
                    obj.DAQ.ClearTask('RunningCounter'); % if tracking
                    obj.DAQ.ClearTask('RunningPulseTrain');
                                                   
                    obj.DAQ.CreateTask('Counter2');
                    counterLine = 2;
                    
                    obj.DAQ.ConfigureCounterIn('Counter2',counterLine,NPulseSamples);
                    obj.gesr.counterData = zeros(1,NPulseSamples); %obj.gesr.counterData = [];
                    obj.DAQ.StartTask('Counter2');
                    pause(0.1);
                    obj.pulseBlaster.setCurrentPulse(totalSequence);
                    obj.pulseBlaster.loadToPulseblaster();
                    obj.pulseBlaster.runPulse();
                    
                    % each frequency step has the same pulse sequence, so
                    % we do not need to load it again here.
                    obj.gesr.GetCountsUntilBuffersFilled(numSignalBuffers);
                    
                    obj.DAQ.StopTask('Counter2');
                    
                    obj.DAQ.ClearTask('Counter2');
                    
                    obj.gesr.counterData = diff(obj.gesr.counterData);
                    signalPoint = sum(obj.gesr.counterData(1:numReadBuffersPerCounter:end))/(repsPerFreqPoint*(signalReadoutTime)*1e-6);
                    refPoint = sum(obj.gesr.counterData(3:numReadBuffersPerCounter:end))/(repsPerFreqPoint*(refReadoutTime)*1e-6);
                    rawSignalPlot(jFreqStep,1) = signalPoint;
                    rawRefPlot(jFreqStep,1) = refPoint;
                    

                    if obj.gesr.stopScan
                        break; % made sure to have this AFTER stopTask on DAQ.
                    end
                    
                    tempXTau = listFreq*10^-6; % MHz plot on x axis
                    plot(currentAxes,...
                        tempXTau,rawRefPlot(:,1),'b',...
                        tempXTau,rawSignalPlot(:,1),'m',...
                        tempXTau,avgRefPlot,'g',...
                        tempXTau,avgSignalPlot,'k');
                    title(currentAxes, 'Raw Data');
                    legend(currentAxes, 'New reference','New signal',...
                        'Average reference','Average signal', 'Location','South');
                    xlabel(currentAxes,'Frequency (MHz)');   
                    ylabel(currentAxes,'PL (kCounts/s)');
                    jFreqStep = jFreqStep + 1;
                    obj.pulseBlaster.stopPulse();
                    %################################################
                    % tracking sequence
                    %################################################
                    compteur = compteur + 1;
                    
                    if get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
                    
                        if(refReady == 0)
                    
                            if(garbage == 1)
                        
                                if(compteur == str2num(get(esrGUI.trackingGarbagePoints,'String')))
                                
                                    garbage = 0;
                                    ref = 0;
                                    refReady = 0;
                                    compteur = 0;
                                end
                            else
                            
                                ref = ref + refPoint;
                                
                                if(compteur == str2num(get(esrGUI.pulseTrackingPeriod,'String')))
                                        ref = ref/(compteur);
                                        refReady = 1;
                                        compteur = 0;
                                end
                            
                            
                            end
                            
                            tempTSteps = str2num(get(esrGUI.stepsSinceTracking,'String'));
                            set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                        
                        else
                    
                            signal = signal + refPoint;
                    
                            if(compteur == str2num(get(esrGUI.pulseTrackingPeriod,'String')))
                            
                                signal = signal/(compteur);
                                
                                if(signal > str2num(get(esrGUI.trackingCountThreshold,'String'))*ref)
                                
                                    signal = 0;
                                    compteur = 0;
                                    tempTSteps = str2num(get(esrGUI.stepsSinceTracking, 'String'));
                                    set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                            
                                else
                          
                                    ref = 0;
                                    refReady = 0;
                                    garbage = 1;
                                    signal = 0;
                                    compteur = 0;
                                    
                                    %initialisation of the AOM for tracking
                                    obj.pulseBlaster.setCurrentPulse( pulseTrackingNum);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String'))); 
                                    
                                    obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
                                    
                                    if get(esrGUI.checkboxUseImageRegistration,'Value')
                                        obj.PerformImageRegistration(0,0);
                                    end
                        
                                    set(esrGUI.stepsSinceTracking, 'String', num2str(0));
                        
                                    %added here on 05/11/2012 to re-initialize the AOM
                                    %before starting a new measurement
                                    %==================================================
                                    obj.pulseBlaster.stopPulse();
                                    obj.pulseBlaster.setCurrentPulse(totalSequence);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String')));
                                    %==================================================
                                end
                            else
                            
                                tempTSteps = str2num(get(esrGUI.stepsSinceTracking, 'String'));
                                set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                            end
                        end
                    end
                       
                    %################### Tracking done ##########################
                end % end loop through frequency points sweep
              
                rawNormPlot(:,1) = rawSignalPlot(:,1)./rawRefPlot(:,1);
                
                avgSignalPlot = (avgSignalPlot.*(jPlot-1)+rawSignalPlot(:,1) )/jPlot;
                avgRefPlot = (avgRefPlot.*(jPlot-1)+rawRefPlot(:,1) )/jPlot;
                
                totalNormPlot = ( totalNormPlot*(jPlot-1) + rawNormPlot(:,1))/jPlot;

                tempXTau = listFreq*10^-6; % MHz plot on x axis
                plot(averageAxes,tempXTau,totalNormPlot,'ro-');
                title(averageAxes, 'Averaged data, normalized to reference after each sweep');
                xlabel(averageAxes,'Frequency (MHz)');
                ylabel(averageAxes,'PL (sig)/ref');
              
                %%%%%%Write the data to a file if we are supposed to on this
                %step
                % do not save the data if we have stopped in the middle of
                % taking tau points, since the file will have useless NANs
                if ( mod(jPlot, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
                    
                    [fida,~] = obj.gesr.DefineESRDataSavePath(esrGUI,numSignalBuffers);
                    fprintf(fida, '%s\t%s\t%s\t%s\n', '2Tau','rawSignal','rawRef','totalNorm');
                    fprintf(fida, '%e\t%e\t%e\t%e\n', [(listFreq*10^-6)'; rawSignalPlot(:,1)'; rawRefPlot(:,1)'; totalNormPlot']);
                    fclose(fida);
                    clear fida
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                jPlot = jPlot + 1;
                set(esrGUI.numCompleted, 'String', num2str(jPlot-1));
                
             end % end loop through specified number of total plot averages
             
             % after the sequence is finished for all averages
            obj.pulseBlaster.stopPulse(); 
            if obj.imageScanHandles.configS.bHaveInverterBoard==0
                % no inverter board so by default have laser back on
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                obj.pulseBlaster.loadToPulseblaster();
                obj.pulseBlaster.runPulse();
            end
            %fopen(obj.srs);
            if useSRS2inPESR == 1
                fprintf(obj.srs2, ['ENBR ', '0']); % turn off the N RF output
                fclose(obj.srs2);
                
                fopen(obj.srs);
                fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
                fclose(obj.srs);
            else
                fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
                fclose(obj.srs);
                
                if bUseSRS2
                    fopen(obj.srs2);
                    fprintf(obj.srs2, ['ENBR ', '0']); % turn off the N RF output
                    fclose(obj.srs2);
                end
            end
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
            Scan_Finished_Flag = 1;
        end
        
        function PerformPiPulsePowerCalibration(obj, esrGUI)
            obj.gesr.UpdateFileNumber(esrGUI);
            
            %safety check
            inputAmp = str2double(get(esrGUI.amplitude,'String'));
            inputAmpB = str2double(get(esrGUI.amplitudeB,'String'));
            if (inputAmp > -1) || (inputAmpB > -1)
                danger = questdlg('The amplitude is high for a pulsed esr measurement. Do you still want to run?','High power warning!','Abort','Run','Abort');
                switch(danger)
                    case 'Abort'
                        return
                        % exit the perform sequence if user chooses to stop

                    case 'Run'
                        % continue on  
                end
            end 
            fclose(obj.srs);
            fopen(obj.srs);
                % Ntype selected
                fprintf(obj.srs, ['ENBL ', '0']);
                fprintf(obj.srs, ['ENBR ', '1']);
            fclose(obj.srs);
            obj.gesr.stopScan = false; %Stop any scans if they are already running
            obj.gesr.DisableGui(esrGUI); %disable the gui so the user cannot chnge parameters during a sweep
            obj.gesr.setAmp(esrGUI); %Set the amplitude
            obj.gesr.setFreq(esrGUI);
            set(esrGUI.numCompleted, 'String', num2str(0)); % reset this before starting new
            set(esrGUI.stepsSinceTracking, 'String', num2str(0)); % reset this before starting new
            
            % variables for determining when to track
            garbage = 1;
            refReady = 0;
            ref = 0;
            signal = 0;
            compteur = 0;
            
            INST_LONG_DELAY = 7;
            INST_CONTINUE = 0;
            INST_BRANCH = 6;
            INST_STOP = 1;
            MINPULSE = 10; % nanoseconds, five 2 ns clock cycles of the PBlaster
            esrStructFilename = get(esrGUI.fileboxPulseSequence,'String');
            esrStruct = tdfread(esrStructFilename);
            [numBits, tempSize] = size(fieldnames(esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
            pulseStr = cell(numBits, 1);
            pulseNum = cell(numBits, 1);
            numInstructions = zeros(1,numBits);
            fieldnames(esrStruct)
            for nb = 1:numBits
                % load ESRPulse requires a full pathname to load from
                % in new code, make the .esr file not require full path
                % name but just get it from the pathname of the .esr file
                % itself. 
                pathESR = regexprep(esrStructFilename,'.esr','');
                %pathBitString = ['esrStruct.bit' num2str(nb)]
                pathBitString = [pathESR '_bit' num2str(nb) '.txt'];
                tempCell = obj.pulseBlaster.loadESRPulse(pathBitString);

                pulseStr{nb} = tempCell;
               % size( tempCell{1})
                [numInstructions(1,nb), ~] = size( tempCell{1});

                % prepare a numerical array for the instructions once eval'd
                pulseNum{nb} = zeros(numInstructions(1,nb),5);
            end
            
            centerFreq = str2num(get(esrGUI.centerFreq, 'String'));
            centerAmpl = str2num(get(esrGUI.amplitude,'String'));
            numAmplSteps = str2num(get(esrGUI.numAmplPoints, 'String'));
            numAverages = str2num(get(esrGUI.numAverages, 'String'));
            repsPerAmplPoint = str2num(get(esrGUI.repsPerAmplPoint,'String'));
            ampldev = str2num(get(esrGUI.pulseAmplDeviation, 'String'));
            amplSweepRange = centerAmpl + ampldev*[-1 1]; % set freq range
            
            listAmpl = linspace(amplSweepRange(1), amplSweepRange(2), numAmplSteps)';
            
            numSignalBuffers = 1;
            numTriggers = 1;
            
            
            %++++++++++++++++++++++++++
            pulseTimeStruct = obj.GetPulseTimeParametersFromGUI(esrGUI);
            signalReadoutTime = pulseTimeStruct.r;
            refReadoutTime = pulseTimeStruct.r;
            
            if get(esrGUI.checkboxSignal50ns,'Value')==1
                signalReadoutTime = signalReadoutTime-50;
            end
            if get(esrGUI.checkboxReference50ns,'Value')==1
                refReadoutTime = refReadoutTime-50;
            end
            
            if get(esrGUI.radio1Channel,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 1;
                numReadBuffersPerCounter = 4; %1/1 = 1
            elseif get(esrGUI.radio2Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 4; %2/2 = 1
            elseif get(esrGUI.radio4Channel,'Value') == 1
                numTriggers = 2;
                numSignalBuffers = 4;
                numReadBuffersPerCounter = 8; %4/2 = 2
            elseif get(esrGUI.radio1Trig2Sig,'Value') == 1
                numTriggers = 1;
                numSignalBuffers = 2;
                numReadBuffersPerCounter = 8; %2/1 = 2
            end
            NPulseSamples = repsPerAmplPoint*numReadBuffersPerCounter+1; % don't use obj.NSamples, reserved for CW
            obj.gesr.counterData = zeros(1,NPulseSamples);
            obj.gesr.counterData2 = zeros(1,NPulseSamples);
            %+++++++++++++++++++++++++++++
            rawSignalPlot = zeros(length(listAmpl),1);
            rawRefPlot = zeros(length(listAmpl),1);
            rawNormPlot = zeros(length(listAmpl),1);
            avgSignalPlot = zeros(length(listAmpl),1);
            avgRefPlot = zeros(length(listAmpl),1);
            totalNormPlot = zeros(length(listAmpl),1);
            if numSignalBuffers == 2
                    rawSignalPlot2 = zeros(length(listAmpl),1);
                    rawRefPlot2 = zeros(length(listAmpl),1);
                    rawNormPlot2 = zeros(length(listAmpl),1);
                    avgSignalPlot2 = zeros(length(listAmpl),1);
                    avgRefPlot2 = zeros(length(listAmpl),1);
                    totalNormPlot2 = zeros(length(listAmpl),1);
            end
            obj.gesr.fileWriteFrequency = str2num(get(esrGUI.writeDataFreq,'String'));
            obj.gesr.fileWritePathname = get(esrGUI.esrSavePath,'String');
            obj.gesr.fileWriteFilename = get(esrGUI.esrSaveFilePrefix,'String');
            obj.gesr.fileWriteFileNum = get(esrGUI.esrSaveFileNum,'String');
            %Computation of the tracking sequence
            %==============================================================
            % we use a on/off AOM sequence for tracking.
             esrTrackingStruct = tdfread([obj.imageScanHandles.configS.sequenceFolder 'TrackingAOMDutyCycle.esr']);
             tempCell = obj.pulseBlaster.loadESRPulse(eval(['esrTrackingStruct.bit' num2str(1)]));

             [numTrackingInstructions, ~] = size( tempCell{1});

             % prepare a numerical array for the instructions once eval'd
             pulseTrackingNum = zeros(numTrackingInstructions,5);
             for k = 1:numTrackingInstructions
                 
                aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), 0, pulseTimeStruct); 
                durExprSingle = durExpr{1};
                durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), 0); 
                durExprSingle2 = durExpr2{1};

                pulseTrackingNum(k,5) = eval(durExprSingle);
                pulseTrackingNum(k,4) = eval(durExprSingle2);
                pulseTrackingNum(k,3) = tempCell{1,3}(k);
                pulseTrackingNum(k,2) = aomExpr;%tempCell{1,2}(k);
                pulseTrackingNum(k,1) = tempCell{1,1}(k);
             end
                        
             clear tempCell;
            %==============================================================
            
            %Open the RF generator and initialize a list of SG states
            fopen(obj.srs);
            fprintf(obj.srs, ['LSTC? ', num2str(length(listAmpl))]); % create a list of SG states
            fprintf(obj.srs, '*CLS');
            %listFreq = listFreq*(10^6); % change to Hz units
            for i = 1:length(listAmpl)
                   % pre-load each state of the list into the SG384 memory
                   % first slot is center frequency, third slot is
                   % amplitude
                   fprintf(obj.srs, ['LSTP ',num2str(i-1),',N,N,N,N,',num2str(listAmpl(i)),',N,N,N,N,N,N,N,N,N,N']);
            end
            % enable the list
            fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
            
            %==============================================================
            %added just to be able to initialize the AOM
            %==============================================================
            if get(esrGUI.checkboxPiCalSetTau,'Value') == 1
                nowTauTime = pulseTimeStruct.p*str2num(get(esrGUI.numPiCycles,'String'));
            else
                tauStart = str2num(get(esrGUI.tauStart,'String'));
                nowTauTime = tauStart;
            end
            
             for mb = 1:numBits
                       for k = 1:numInstructions(1,mb)
                           tempCell = pulseStr{mb};
                           
                           aomExpr = obj.FlipAOMBitForNoInverter(tempCell{1,2}(k)); 
                           durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k), nowTauTime, pulseTimeStruct); 
                           durExprSingle = durExpr{1};
                           durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k), pulseTimeStruct.n); 
                           durExprSingle2 = durExpr2{1};

                           pulseNum{mb}(k,5) = eval(durExprSingle);
                           pulseNum{mb}(k,4) = eval(durExprSingle2);
                           pulseNum{mb}(k,3) = tempCell{1,3}(k);
                           if mb == 1
                               if tempCell{1,2}(k) == 0
                                   pulseNum{mb}(k,2) = 14680065;
                               elseif tempCell{1,2}(k) == 14680065
                                   pulseNum{mb}(k,2) = 0;
                               end
                           else
                               pulseNum{mb}(k,2) = tempCell{1,2}(k);
                           end
                           pulseNum{mb}(k,1) = tempCell{1,1}(k);
                           
                           clear tempCell;
                       end
              end
                    
                    % next, must reconcile these sequences and change the
                    % stop command to a branch command
                    pulseSequenceString = [];
                    for nn = 1:numBits
                        if nn==numBits
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '}'];
                        else
                            pulseSequenceString = [pulseSequenceString 'pulseNum{' num2str(nn) '},'];
                        end
                    end
                    totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
                    sizeConcatenatedSequences = size(pulseSequenceString);
                    clear pulseSequenceString; % we reinitialized this every loop so free the memory!
                    [totalNumInstructions, ~] = size(totalSequence);
                    if totalSequence(totalNumInstructions,3) == INST_STOP
                        totalSequence(totalNumInstructions,3) = INST_BRANCH;
                    end
                    if totalSequence(totalNumInstructions,5) < MINPULSE
                        totalSequence(totalNumInstructions,5) = MINPULSE;
                        % in case combining the pulses somehow makes the
                        % last pulse duration = 0, which is not good
                    end
            obj.pulseBlaster.setCurrentPulse(totalSequence);
            %totalSequence
            obj.pulseBlaster.loadToPulseblaster();
            obj.pulseBlaster.runPulse();
            pause(str2num(get(esrGUI.preMeasurePause,'String')));
            %=================================================================                        
            currentAxes = esrGUI.axesCurrentSweep;
            averageAxes = esrGUI.axesNormalized;
            
            jStart = str2num(get(esrGUI.plotAverageToStartAt,'String'));
            jPlot = jStart;
            jCounter = 1; % this counts up from 1 regardless of jStart
            set(esrGUI.numCompleted, 'String', num2str(jPlot-1));
            while jPlot <= numAverages && obj.gesr.stopScan == false
                jAmplStep = 1;
                % we cut and paste the ClearTasks from here for tracking
                while jAmplStep <= length(listAmpl) && obj.gesr.stopScan == false
                    fprintf(obj.srs, '*TRG'); % trigger the list to next amplitude
                    
                    obj.DAQ.ClearTask('RunningCounter'); % if tracking
                    obj.DAQ.ClearTask('RunningPulseTrain');
                                                   
                    %Initialization of the DAQ
                    %=====================================================
                    obj.DAQ.CreateTask('Counter2');
                    counterLine = 2;
                    obj.DAQ.ConfigureCounterIn('Counter2',counterLine,NPulseSamples);
                    obj.gesr.counterData = zeros(1,NPulseSamples); %obj.gesr.counterData = [];
                    
                    if (numSignalBuffers == 2)
                        if (numTriggers == 2)
                            obj.DAQ.CreateTask('Counter');
                            counterLine2 = 1;
                            obj.DAQ.ConfigureCounterIn('Counter',counterLine2,NPulseSamples);
                        end
                        obj.gesr.counterData2 = zeros(1,NPulseSamples); %obj.gesr.counterData2 = [];
                    end
                    
                    obj.DAQ.StartTask('Counter2');
                    if (numSignalBuffers == 2)
                        if (numTriggers==2)
                            obj.DAQ.StartTask('Counter');
                        end
                    end
                    pause(0.1);
                    %=====================================================
                    
                    obj.pulseBlaster.setCurrentPulse(totalSequence);
                    obj.pulseBlaster.loadToPulseblaster();
                    obj.pulseBlaster.runPulse();
                    
                    % each frequency step has the same pulse sequence, so
                    % we do not need to load it again here.
                    obj.gesr.GetCountsUntilBuffersFilled(numSignalBuffers);
                    obj.DAQ.StopTask('Counter2');
                    obj.DAQ.ClearTask('Counter2');
                   
                    obj.gesr.counterData = diff(obj.gesr.counterData);

                    signalPoint = sum(obj.gesr.counterData(1:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(signalReadoutTime)*1e-6);
                    refPoint = sum(obj.gesr.counterData(3:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(refReadoutTime)*1e-6);
                    rawSignalPlot(jAmplStep,1) = signalPoint;
                    rawRefPlot(jAmplStep,1) = refPoint;
                    
                    if (numSignalBuffers == 2)
                        if (numTriggers == 2)
                            obj.gesr.counterData2 = diff(obj.gesr.counterData2);
                            signalPoint2 = sum(obj.gesr.counterData2(1:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(signalReadoutTime)*1e-6);
                            refPoint2 = sum(obj.gesr.counterData2(3:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(refReadoutTime)*1e-6);
                            rawSignalPlot2(jAmplStep,1) = signalPoint2;
                            rawRefPlot2(jAmplStep,1) = refPoint2;

                            obj.DAQ.StopTask('Counter');
                            obj.DAQ.ClearTask('Counter');
                        elseif (numTriggers == 1)
                            signalPoint2 = sum(obj.gesr.counterData(5:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(signalReadoutTime)*1e-6);
                            refPoint2 = sum(obj.gesr.counterData(7:numReadBuffersPerCounter:end))/(repsPerAmplPoint*(refReadoutTime)*1e-6);
                            rawSignalPlot2(jAmplStep,1) = signalPoint2;
                            rawRefPlot2(jAmplStep,1) = refPoint2;
                        end
                    end

                    if obj.gesr.stopScan
                        break; % made sure to have this AFTER stopTask on DAQ.
                    end
                    
                    tempXTau = listAmpl; % power on Xaxis
                    
                    if (numSignalBuffers ==1 )
                        plot(currentAxes,...
                             tempXTau,rawRefPlot(:,1),'b',...
                             tempXTau,rawSignalPlot(:,1),'m',...
                             tempXTau,avgRefPlot,'g',...
                             tempXTau,avgSignalPlot,'k');
                        title(currentAxes, 'Raw Data');
                        legend(currentAxes, 'New reference','New signal',...
                             'Average reference','Average signal', 'Location','South');
                    elseif (numSignalBuffers == 2)
                        plot(currentAxes,...
                        tempXTau,rawRefPlot(:,1),'b',...
                        tempXTau,rawSignalPlot(:,1),'m',...
                        tempXTau,avgRefPlot,'g--',...
                        tempXTau,avgSignalPlot,'k--',...
                        tempXTau,rawRefPlot2(:,1),'r',...
                        tempXTau,rawSignalPlot2(:,1),'y',...
                        tempXTau,avgRefPlot2,'c-',... %need other color
                        tempXTau,avgSignalPlot2,'k-'); %need other colors
                    
                        title(currentAxes, 'Raw Data');
                    
                        legend(currentAxes, 'New reference1','New signal1',...
                            'Average reference1','Average signal1','New reference2','New signal2',...
                            'Average reference2','Average signal2', 'Location','South');
                    end
                    jAmplStep = jAmplStep + 1;
                    
                    obj.pulseBlaster.stopPulse();
                    %################################################
                    % tracking sequence
                    %################################################
                    compteur = compteur + 1;
                    if get(esrGUI.checkboxUseTracking,'Value')==1 && ~isempty(obj.imageScanHandles)
                    
                        if(refReady == 0)
                    
                            if(garbage == 1)
                        
                                if(compteur == str2num(get(esrGUI.trackingGarbagePoints,'String')))
                                
                                    garbage = 0;
                                    ref = 0;
                                    refReady = 0;
                                    compteur = 0;
                                end
                            else
                            
                                ref = ref + refPoint;
                                
                                if(compteur == str2num(get(esrGUI.pulseTrackingPeriod,'String')))
                                        ref = ref/(compteur);
                                        refReady = 1;
                                        compteur = 0;
                                end
                            
                            
                            end
                            
                            tempTSteps = str2num(get(esrGUI.stepsSinceTracking,'String'));
                            set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                        
                        else
                    
                            signal = signal + refPoint;
                    
                            if(compteur == str2num(get(esrGUI.pulseTrackingPeriod,'String')))
                            
                                signal = signal/(compteur);
                                
                                if(signal > str2num(get(esrGUI.trackingCountThreshold,'String'))*ref)
                                
                                    signal = 0;
                                    compteur = 0;
                                    tempTSteps = str2num(get(esrGUI.stepsSinceTracking, 'String'));
                                    set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                            
                                else
                          
                                    ref = 0;
                                    refReady = 0;
                                    garbage = 1;
                                    signal = 0;
                                    compteur = 0;
                                    
                                    %initialisation of the AOM for tracking
                                    obj.pulseBlaster.setCurrentPulse( pulseTrackingNum);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String'))); 
                                    
                                    obj.gesr.RunSingleTrackPulsedESR(obj.imageScanHandles);
                                    
                                    if get(esrGUI.checkboxUseImageRegistration,'Value')
                                        obj.PerformImageRegistration(0,0);
                                    end
                        
                                    set(esrGUI.stepsSinceTracking, 'String', num2str(0));
                        
                                    %added here on 05/11/2012 to re-initialize the AOM
                                    %before starting a new measurement
                                    %==================================================
                                    obj.pulseBlaster.stopPulse();
                                    obj.pulseBlaster.setCurrentPulse(totalSequence);
                                    obj.pulseBlaster.loadToPulseblaster();
                                    obj.pulseBlaster.runPulse();
                                    pause(str2num(get(esrGUI.preMeasurePause,'String')));
                                    %==================================================
                                end
                            else
                            
                                tempTSteps = str2num(get(esrGUI.stepsSinceTracking, 'String'));
                                set(esrGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                            end
                        end
                    end
                       
                    %################### Tracking done ##########################
                end % end loop through frequency points sweep
              
                % update the normalized and averaged plots--------------
                rawNormPlot(:,1) = rawSignalPlot(:,1)./rawRefPlot(:,1);
                avgSignalPlot = (avgSignalPlot.*(jCounter-1)+rawSignalPlot(:,1) )/jCounter;
                avgRefPlot = (avgRefPlot.*(jCounter-1)+rawRefPlot(:,1) )/jCounter;
                totalNormPlot = ( totalNormPlot*(jCounter-1) + rawNormPlot(:,1))/jCounter;
                if (numSignalBuffers == 2)
                    rawNormPlot2(:,1) = rawSignalPlot2(:,1)./rawRefPlot2(:,1);
                    avgSignalPlot2 = (avgSignalPlot2.*(jCounter-1)+rawSignalPlot2(:,1) )/jCounter;
                    avgRefPlot2 = (avgRefPlot2.*(jCounter-1)+rawRefPlot2(:,1) )/jCounter;
                    totalNormPlot2 = ( totalNormPlot2*(jCounter-1) + rawNormPlot2(:,1))/jCounter;
                end
                %-------------------------------------------------------
                

                tempXTau = listAmpl; % power on x axis                
                if (numSignalBuffers == 1)
                    plot(averageAxes,tempXTau,totalNormPlot,'ro-');
                elseif (numSignalBuffers == 2)
                    plot(averageAxes,tempXTau,totalNormPlot,'ro-',...
                    tempXTau,totalNormPlot2,'bo-');
                    legend(currentAxes, 'Norm trace 1','Norm trace 2','Location','South');
                end
                title(averageAxes, 'Averaged data, normalized to reference after each sweep');
                xlabel(averageAxes,'Microwave Amplitude (dBm)');    
                ylabel(averageAxes,'PL (sig)/ref');
              
                %%%%%%Write the data to a file if we are supposed to on this
                %step
                % do not save the data if we have stopped in the middle of
                % taking tau points, since the file will have useless NANs
                if ( mod(jPlot, obj.gesr.fileWriteFrequency) == 0 && obj.gesr.stopScan == false )
                    
                    [fida,fidb] = obj.gesr.DefineESRDataSavePath(esrGUI,numSignalBuffers);
                    fprintf(fida, '%s\t%s\t%s\t%s\n', '2Tau','rawSignal','rawRef','totalNorm');
                    fprintf(fida, '%e\t%e\t%e\t%e\n', [(listAmpl*10^-6)'; rawSignalPlot(:,1)'; rawRefPlot(:,1)'; totalNormPlot']);
                    fclose(fida);
                    clear fida
                    
                    if (numSignalBuffers==2)
                        fprintf(fidb, '%s\t%s\t%s\t%s\n', '2Tau','rawSignal','rawRef','totalNorm');
                        fprintf(fidb, '%e\t%e\t%e\t%e\n', [(listAmpl*10^-6)'; rawSignalPlot2(:,1)'; rawRefPlot2(:,1)'; totalNormPlot2']);
                        fclose(fidb);
                        clear fidb
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                jPlot = jPlot + 1;
                jCounter=jCounter+1;
                % numCompleted must be kept as jPlot to do the saving
                % correctly
                set(esrGUI.numCompleted, 'String', num2str(jPlot-1)); 
                obj.pulseBlaster.stopPulse(); % stop the pulse sequence if tracking
                
             end % end loop through specified number of total plot averages
             
             % after the sequence is finished for all averages
            obj.pulseBlaster.stopPulse(); 
            if obj.imageScanHandles.configS.bHaveInverterBoard==0
                % no inverter board so by default have laser back on
                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                obj.pulseBlaster.loadToPulseblaster();
                obj.pulseBlaster.runPulse();
            end
            %fopen(obj.srs);
            fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
            fclose(obj.srs);
            obj.gesr.EnableGui(esrGUI);
            obj.gesr.stopScan = false;
        end
        
                function [confocalVoltagesOutX confocalVoltagesOutY] = InitializeConfocalVoltages(obj, sizeDimIn_nm, confocalCenterInX_um, confocalCenterInY_um, pixelsPerDim)
           
           % first get the cursor position to start with in [µm]
           % recall "handles" refers to ImageScan list of handles as that
           % is the function instantiating this AFMScanPLImages
           
           % check that a full scan box around the cursor will not cause
           % the required voltage to exceed the imposed AnalogOut limts
           xlim = [(confocalCenterInX_um - 0.5*sizeDimIn_nm*0.001)...
               (confocalCenterInX_um + 0.5*sizeDimIn_nm*0.001)];
           ylim = [(confocalCenterInY_um - 0.5*sizeDimIn_nm*0.001)...
               (confocalCenterInY_um + 0.5*sizeDimIn_nm*0.001)];
           
           dimX = 1;
           dimY = 2;
           
           if xlim(1) < obj.DAQ.AnalogOutMinVoltages(dimX)*obj.UMPerV(dimX)
                    % don't fix the voltage, abort the scan, force user to
                    % choose smaller scan or different area far from border
                    obj.stopScan = true;
                    warndlg('Aborting scan due to scan area exceeding DAQ analog out galvo X voltage min.');
                    return;
           end
            if xlim(2) > obj.DAQ.AnalogOutMaxVoltages(dimX)*obj.UMPerV(dimX)
                 % don't fix the voltage, abort the scan, force user to
                    % choose smaller scan or different area far from border
                    obj.stopScan = true;
                    warndlg('Aborting scan due to scan area exceeding DAQ analog out galvo X voltage max.');
                    return;
            end
            if ylim(1) < obj.DAQ.AnalogOutMinVoltages(dimY)*obj.UMPerV(dimY)
                % don't fix the voltage, abort the scan, force user to
                    % choose smaller scan or different area far from border
                    warndlg('Aborting scan due to scan area exceeding DAQ analog out galvo Y voltage min.');
                    obj.stopScan = true;
                    return;
            end
            if ylim(2) > obj.DAQ.AnalogOutMaxVoltages(dimY)*obj.UMPerV(dimY)
                % don't fix the voltage, abort the scan, force user to
                    % choose smaller scan or different area far from border
                    warndlg('Aborting scan due to scan area exceeding DAQ analog out galvo Y voltage max.');
                    obj.stopScan = true;
                    return;
            end
            
            % from these validated limits in [µm], compute voltage lists
            % these are not yet in raster scan ordering and x,y pairing
            %obj.minConfocalValues_nm(1) = xlim(1)*1000;
            %obj.minConfocalValues_nm(2) = ylim(1)*1000;
            %obj.maxConfocalValues_nm(1) = xlim(2)*1000;
            %obj.maxConfocalValues_nm(2) = ylim(2)*1000;
            
            Vx = linspace(xlim(1),xlim(2),pixelsPerDim);
            confocalVoltagesOutX = Vx * obj.VPerUM(dimX);
            
            Vy = linspace(ylim(1),ylim(2),pixelsPerDim);
            confocalVoltagesOutY = Vy * obj.VPerUM(dimY);
            
            
        end
       
        function [confocalTuplesOutV] = GenerateConfocalRasterVoltages(obj, confocalVoltagesInX, confocalVoltagesInY)
          % make the voltage tuples in the raster scanning order
          % this is for the galvo
          
          % all typical scans should be 2D, X and Y
          Va = confocalVoltagesInX;%obj.XConfocalVoltages;
          Vb = confocalVoltagesInY;%obj.YConfocalVoltages;
          
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
            %second is Y. n rows by 2 columns.
            %obj.confocalVoltageTuples = reshape(VoltageMatrix,[],2,1);
            confocalTuplesOutV = reshape(VoltageMatrix,[],2,1);
            
        end
       
        
        function PerformImageRegistration(obj, esrGUI, bOriginalImage)
            
            cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
            cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String'));
            cursOff = zeros(1,2);
                                    
            cursOff(1) = cursorInX;
            cursOff(2) = cursorInY;
            
            if bOriginalImage==1
               % if starting the measurement, this position is original
               obj.originalCursorX_um = cursorInX;
               obj.originalCursorY_um = cursorInY;
            end
            
            obj.imageRegScanSize = 2;
            obj.imageRegPointsPerLine = 50;
            obj.imageRegDwellTime = 0.004;
           
            [regVoltagesX regVoltagesY] =...
                obj.InitializeConfocalVoltages(obj.imageRegScanSize*1000, cursOff(1), cursOff(2), obj.imageRegPointsPerLine );
            regVoltageTuples=obj.GenerateConfocalRasterVoltages(regVoltagesX,regVoltagesY);
        
        
        % do the scan
           Na = obj.imageRegPointsPerLine;
           regNSamples = Na^2 + 1;
           dwell = obj.imageRegDwellTime;
           dutyCycle = 0.5;
           VoltageLines = [1,2]; % x, y dimension indices
           clockFrequency = 1/dwell;
           indexRegCounterData = 0;
           regCounterData = [] ;
           regScanData = [];
           % pulse train clocks position and counter
           obj.DAQ.CreateTask('PulseTrain');
           obj.DAQ.ConfigureClockOut('PulseTrain', DAQManager.CLK1,clockFrequency,dutyCycle);
           % voltages to galvo
           obj.DAQ.CreateTask('VoltageOut');
           obj.DAQ.ConfigureVoltageOut('VoltageOut',VoltageLines,regVoltageTuples(:),DAQManager.CLK1);
           % counter for PL
           obj.DAQ.CreateTask('Counter');
           obj.DAQ.ConfigureCounterIn('Counter',DAQManager.CTR1,regNSamples);
           obj.DAQ.StartTask('Counter');
           obj.DAQ.StartTask('VoltageOut');
           pause(0.3);
           % start the sample clock
           if obj.gesr.stopScan == false
           %because of pause(.3), we need to check if externally stopped
               obj.DAQ.StartTask('PulseTrain');
           end
           % scan start done. now loop until all samples are acquired
          % while (obj.gesr.stopScan == false) && (obj.DAQ.IsTaskDone('Counter') == false)
           while (obj.DAQ.IsTaskDone('Counter') == false)
                % read counter buffer
                regNSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                iSample = indexRegCounterData + 1;
                jSample = indexRegCounterData + regNSamplesAvailable; %index of last new sample
                increment = 1;
                regCounterData(iSample:increment:jSample) = obj.DAQ.ReadCounterBuffer('Counter',regNSamplesAvailable);
                indexRegCounterData = jSample;
                %-----------
                pause(0.1);%seconds
           end
           
           % do one last sample dump to be sure we got all
           regNSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
           iSample = indexRegCounterData + 1;
           jSample = indexRegCounterData + regNSamplesAvailable; %index of last new sample
           increment = 1;
           regCounterData(iSample:increment:jSample) = obj.DAQ.ReadCounterBuffer('Counter',regNSamplesAvailable);
           
           %clear scan tasks,
            obj.DAQ.ClearTask('Counter');
            obj.DAQ.ClearTask('VoltageOut');
            obj.DAQ.ClearTask('PulseTrain');
            
           regScanData = abs(diff(regCounterData))/(1000*dwell);
           %mean(regScanData) % debug
           size(regScanData)
           Na
           regScanData = reshape(regScanData,Na,Na);
           regScanData(:,2:2:end) = flipud(regScanData(:,2:2:end));
           regScanDataTranspose = regScanData';
           %transpose ' and save to correct image matrix
           if (bOriginalImage==1)
               obj.imageDataOriginalNVPL=regScanDataTranspose;
               obj.imageDataCurrentNVPL=regScanDataTranspose;
               
               fInImage = regScanDataTranspose;
               gInImage = regScanDataTranspose;
           else
               obj.imageDataCurrentNVPL=regScanDataTranspose;
               fInImage = obj.imageDataOriginalNVPL;
               gInImage =  obj.imageDataCurrentNVPL;
           end
           
           imageRegSubPixelFactor=100;
           % perform the registration 
           [outRegValues GOutRegImage] = dftregistration(fft2(fInImage),fft2(gInImage),imageRegSubPixelFactor);
           display(outRegValues)
           
           obj.hImageRegNVPLFig=65423;
           figReg = figure(obj.hImageRegNVPLFig);
           set(gcf,'Name','NV PL Image Registration');
           tempFigPos = get(gcf,'Position');
           set(gcf,'Position',[tempFigPos(1) tempFigPos(2) 804 224]);
           set(gcf,'ToolBar','none');
        
        clf(figReg);
           fgLineSize = obj.imageRegScanSize;
           xylimReg = [-fgLineSize*0.5 fgLineSize*0.5];
           % show OriginalImage, CurrentImage, Registered Current image
           subplot(1,3,1);
           imagesc([xylimReg(1),xylimReg(2)],...
	        		[xylimReg(1),xylimReg(2)],...
                    fInImage);%caxis(fInImage));
           title('Reference image, f(x,y)');
           xlabel('X aro. laser (µm)'); ylabel('Y aro. laser (µm)');
           set(gca,'YDir','Normal');
           colormap(pink(64));
           %
           subplot(1,3,2);
           imagesc([xylimReg(1),xylimReg(2)],...
	        		[xylimReg(1),xylimReg(2)],...
                    gInImage);%caxis(fInImage));
           title('New image, g(x,y)');
           xlabel('X aro. laser (µm)'); ylabel('Y aro. laser (µm)');
           set(gca,'YDir','Normal');
           %
           subplot(1,3,3);
           imagesc([xylimReg(1),xylimReg(2)],...
	        		[xylimReg(1),xylimReg(2)],...
                    abs(ifft2(GOutRegImage)));%,caxis(fInImage));
           title('New image registered to ref., gr(x,y)');
           xlabel('X aro. laser (µm)'); ylabel('Y aro. laser (µm)');
           set(gca,'YDir','Normal');
           
           % use the outRegValues to adjust the laser..
           netRowShift = outRegValues(3); % in fractional pixels
           netColShift = outRegValues(4); % in fractional pixels
           
           % convert fractional pixels to µm
           % make sure I know which direction 
           % a column shift in the example looks like X axis.
           % it also looks like a left shift is -col shift.
           rowShift_um = netRowShift*obj.imageRegScanSize/obj.imageRegPointsPerLine
           colShift_um = netColShift*obj.imageRegScanSize/obj.imageRegPointsPerLine
           
           % correct the hardware setting if this is not the first image
           if (bOriginalImage==0)
               'do something'
               % correct for the laser-NV offset by moving laser. 
                    newCX = cursorInX-colShift_um;
                    newCY = cursorInY-rowShift_um;
                    set(obj.imageScanHandles.editPositionX, 'String', num2str(newCX));
                    set(obj.imageScanHandles.editPositionY, 'String', num2str(newCY));
                    obj.imageScanHandles.CursorControl.deleteManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.createManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 1, newCX);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 2, newCY);
           else
               % otherwise just leave the cursor where it is
                newCX = cursorInX;
                newCY = cursorInY;
                set(obj.imageScanHandles.editPositionX, 'String', num2str(newCX));
                    set(obj.imageScanHandles.editPositionY, 'String', num2str(newCY));
                    obj.imageScanHandles.CursorControl.deleteManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.createManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 1, newCX);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 2, newCY);
           end
        end
        
        function [final_Instruction, numInstructions] = quantumInterpolationExpansion_compress(obj,Instruction,nowTauTime,nn,yy)

            %NOTE: This function was implemented by Dolev Bluvstein on 1/18/2018. It
            %allows for "supersampling" beoynd the 2 ns resolution of the pulseblaster in 
            %an XY8 measurement. If you, for example, are doing 64 pulses with 
            %2 tau = 200 ns spacing, the next best you can do is 2 tau = 204 ns
            %spacing. With this interpolation technique, you can make 63 pulses 2 tau =
            %200 ns, and one of the 64 pulses you make 2 tau = 204 ns. Now you
            %effectively have 2 tau = 200.0625 ns. Your frequency resolution improves
            %by orders of magnitude. This "quantum interpolation" technique is taken
            %from "Quantum Interpolation for High Resolution Sensing" by Ashok Ajoy
            %(2017). The supplement explains how to construct the optimal supersampling
            %sequence, and MATLAB code is given at the end, in part modified here.

            %AS WRITTEN, this function will only work for an XY8 sequence with loops of t and y-t loop.
            %using y in any other way will not work and will compile your interpolation incorrectly.
            %YOU MUST also write the pulse sequence with 't' and never '2t'. So you have to
            %repeat a line that has '2t' delay and write 't' and then 't' again on the next line.

            delay{nn*16,1}=[];% Initialize cell array 'delay' 
            count=1; mm=0;

            sample = mod(nowTauTime,2)/2;

            t_floor = num2str(2*floor(nowTauTime/2));
            t_floor_2 = num2str(2*floor(nowTauTime/2)+2);

            for jj=1:(4*nn) % HerenisXYBcyclenumber 
                mm = mm + sample;
            % sample is a fraction number between 0 and 1, rounded to multiples of 1/(4*n);
                    if abs(mm) <= 1/2
                        delay{count} = t_floor;
                        delay{count+1} = t_floor;
                        delay{count+2} = t_floor;
                        delay{count+3} = t_floor;
                        count = count+4;
                    else
                        delay{count} = t_floor_2;
                        delay{count+1} = t_floor_2;
                        delay{count+2} = t_floor_2;
                        delay{count+3} = t_floor_2; %2 ns is dt, the resolution of pulse blaster
                        count = count+4; 
                        mm = mm-1;
                    end
            end

            delay_y{nn*16,1}=[];% Initialize cell array 'delay_y' 
            count=1; mm=0;

            sample = mod(yy-nowTauTime,2)/2; %%yy-nowTauTime is the time of the second measurement, y-t. Important to remember that y -> y+t

            yminust_floor = num2str(2*floor((yy-nowTauTime)/2));
            yminust_floor_2 = num2str(2*floor((yy-nowTauTime)/2)+2);

            for jj=1:(4*nn) % HerenisXYBcyclenumber 
                mm = mm + sample;
            % sample is a fraction number between 0 and 1, rounded to multiples of 1/(4*n);
                    if abs(mm) <= 1/2
                        delay_y{count} = yminust_floor;
                        delay_y{count+1} = yminust_floor;
                        delay_y{count+2} = yminust_floor;
                        delay_y{count+3} = yminust_floor;
                        count = count+4;
                    else
                        delay_y{count} = yminust_floor_2;
                        delay_y{count+1} = yminust_floor_2;
                        delay_y{count+2} = yminust_floor_2;
                        delay_y{count+3} = yminust_floor_2; %2 ns is dt, the resolution of pulse blaster
                        count = count+4; 
                        mm = mm-1;
                    end
            end

            Instruction{4} = str2double(regexprep(Instruction{4},'n',num2str(nn)));
            Instruction{1} = (0:(length(Instruction{1})-1))';

            find(Instruction{3}==2);
            loop_ends = Instruction{1}(Instruction{3}==3);
            loop_starts = Instruction{4}(loop_ends+1);

            temp_loopmat_num = [];
            temp_loopmat_let = {};

            %NOTE. AS WRITTEN THIS WILL NOT ALLOW FOR NESTED LOOPS. THIS IS FINE FOR
            %THE XY8 MEASUREMENTS I HAVE PLANNED, WHERE THE XY8 IS WRITTEN EXPLICLITY.
            %AS IS, THIS QUANTUM INTERPOLATION SCHEME IS SPECIFICALLY FOR XY8 AND
            %FURTHER CALCULATIONS AND CODING WOULD NEED TO BE DONE FOR XY4,XY16, OR
            %ANY OTHER PULSE SEQUENCE ASIDE FROM XY8-N
            for iL=1:length(loop_starts)
                number_mats = cell2mat(Instruction(2:3));

                if iL == 1
                    top_num = number_mats(1:loop_starts(iL),:);
                    top_let = Instruction{5}(1:loop_starts(iL),:);
                else
                    top_num = number_mats((loop_ends(iL-1) + 2):loop_starts(iL),:);
                    top_let = Instruction{5}((loop_ends(iL-1) + 2):loop_starts(iL),:);
                end

                middle_num = number_mats((loop_starts(iL)+1):(loop_ends(iL)+1),:);
                middle_let = Instruction{5}((loop_starts(iL)+1):(loop_ends(iL)+1),:);

                if iL == length(loop_starts)
                    bottom_num = number_mats((loop_ends(iL)+2):end,:);
                    bottom_let = Instruction{5}((loop_ends(iL)+2):end,:);
                else
                    bottom_num = [];
                    bottom_let = {};
                end

                middle_num(1,2) = 0;
                middle_num(end,2) = 0;

                middle_num_expand = repmat(middle_num,nn,1);
                middle_let_expand = repmat(middle_let,nn,1); %expand loops

                middle_dt_added = middle_let_expand;

                contains_yminust = any(~cellfun('isempty',strfind(middle_let,'y-t'))); %finds if there are any y-t in here. In that case, use y-t for this expansion.

                iii = 0;
                if ~contains_yminust
                    t_index = strfind(middle_let_expand,'t');
                    for ii = 1:length(middle_let_expand)
                        if t_index{ii} ~= 0
                            iii = iii+1;
                            middle_dt_added{ii} = regexprep(middle_let_expand{ii},'t',['(',delay{iii},')']);
                        end
                    end
                end

                if contains_yminust
                    y_index = strfind(middle_let_expand,'y-t');
                    for ii = 1:length(middle_let_expand)
                        if y_index{ii} ~= 0
                            iii = iii+1;
                            middle_dt_added{ii} = regexprep(middle_let_expand{ii},'y-t',['(',delay_y{iii},')']);
                        end
                    end
                end

                temp_loopmat_num = [temp_loopmat_num; top_num; middle_num_expand; bottom_num];
                temp_loopmat_let = [temp_loopmat_let; top_let; middle_dt_added; bottom_let];

                %have to renumber instruction{1}, have to expand instruction{2} (no dt
                %adding needed), have to make all of instruction{3} = 0 except the end
                %value which has to equal 1, and have to set all instruction{4} = 0.
                %This is because we already expanded the loop.
            end

            %now compress efficiently, allowing for negative delay values and also substantially
            %increasing the speed of the PulseInterpreter function

            for instruction_index = 1:(length(temp_loopmat_let) - 1)
                if temp_loopmat_num(instruction_index,1) == temp_loopmat_num(instruction_index+1,1) %if it's the same instruction, then combine their durations
                    temp_loopmat_let{instruction_index+1} = [temp_loopmat_let{instruction_index},'+',temp_loopmat_let{instruction_index+1}];
                    temp_loopmat_num(instruction_index,2) = 0.1; %mark the top line for later deletion since we added the duration to the bottom line
                end
            end
            delete_index = (temp_loopmat_num(:,2) == 0.1);

            temp_loopmat_let(delete_index) = [];
            temp_loopmat_num(delete_index,:) = []; 

            %now prepare to pass to the normal pulse interpreter function
            final_Instruction{1,5} = [];

            final_Instruction{1,1} = (0:(length(temp_loopmat_let)-1))'; %renumber first column from 0 to end
            final_Instruction{1,2} = temp_loopmat_num(:,1); %bit on/off instruction, expanded
            final_Instruction{1,3} = temp_loopmat_num(:,2); %should be all 0s except 1 at end. I remove all of the loop instructions.
            final_Instruction{1,4} = repmat({'0'},length(temp_loopmat_let),1); %all 0s
            final_Instruction{1,5} = temp_loopmat_let; %delay times, expanded and with +2 in the appropriate locations.

            numInstructions = length(final_Instruction{1,5});
            %final instruction is the expanded form of the commands for 1 bit, with the proper dt's
            %inserted, in the same format from the beginning. It can now be passed onto
            %the remainder of the function as normal, and used for quantum
            %interpolation.
    end
% 
%             function [final_Instruction, numInstructions] = quantumInterpolationExpansion(Instruction,nowTauTime,nn)
% 
%                 %NOTE: This function was implemented by Dolev Bluvstein on 1/11/2018. It
%                 %allows for "supersampling" beoynd the 2 ns resolution of the pulseblaster in 
%                 %an XY8 measurement. If you, for example, are doing 64 pulses with 
%                 %2 tau = 200 ns spacing, the next best you can do is 2 tau = 204 ns
%                 %spacing. With this interpolation technique, you can make 63 pulses 2 tau =
%                 %200 ns, and one of the 64 pulses you make 2 tau = 204 ns. Now you
%                 %effectively have 2 tau = 200.0625 ns. Your frequency resolution improves
%                 %by orders of magnitude. This "quantum interpolation" technique is taken
%                 %from "Quantum Interpolation for High Resolution Sensing" by Ashok Ajoy
%                 %(2017). The supplement explains how to construct the optimal supersampling
%                 %sequence, and MATLAB code is given at the end, in part modified here.
% 
%                 %AS WRITTEN, this function will only work for an XY8 sequence with two
%                 %symmetrized loops, where the second loop is necessarily the y-t loop. You
%                 %must also write the pulse sequence with 't' and never '2t'. So you have to
%                 %repeat a line that has '2t' delay and write 't' and then 't' again on the next line.
% 
%                 delay{nn*16,1}=[];% Initialize cell array 'delay' 
%                 count=1; mm=0;
% 
%                 sample = mod(nowTauTime,2)/2;
% 
%                 for jj=1:(4*nn) % HerenisXYBcyclenumber 
%                     mm = mm + sample;
%                 % sample is a fraction number between 0 and 1, rounded to multiples of 1/(4*n);
%                         if abs(mm) <= 1/2
%                             delay{count} = 't';
%                             delay{count+1} = 't';
%                             delay{count+2} = 't';
%                             delay{count+3} = 't';
%                             count = count+4;
%                         else
%                             delay{count} = 't+2';
%                             delay{count+1} = 't+2';
%                             delay{count+2} = 't+2';
%                             delay{count+3} = 't+2'; %2 ns is dt, the resolution of pulse blaster
%                             count = count+4; 
%                             mm = mm-1;
%                         end
%                 end
% 
%                 Instruction{4} = str2double(regexprep(Instruction{4},'n',num2str(nn)));
%                 Instruction{1} = (0:(length(Instruction{1})-1))';
% 
%                 find(Instruction{3}==2);
%                 loop_ends = Instruction{1}(Instruction{3}==3);
%                 loop_starts = Instruction{4}(loop_ends+1);
% 
%                 temp_loopmat_num = [];
%                 temp_loopmat_let = {};
% 
%                 %NOTE. AS WRITTEN THIS WILL NOT ALLOW FOR NESTED LOOPS. THIS IS FINE FOR
%                 %THE XY8 MEASUREMENTS I HAVE PLANNED, WHERE THE XY8 IS WRITTEN EXPLICLITY.
%                 %AS IS, THIS QUANTUM INTERPOLATION SCHEME IS SPECIFICALLY FOR XY8 AND
%                 %FURTHER CALCULATIONS AND CODING WOULD NEED TO BE DONE FOR XY4,XY16, OR
%                 %ANY OTHER PULSE SEQUENCE ASIDE FROM XY8-N
%                 for iL=1:length(loop_starts)
%                     if iL == 1
%                         delay_choose = delay;
%                     elseif iL == 2
%                         delay_choose = flipud(delay); %NOTE: THIS ONLY WORKS IF YOU HAVE TWO LOOPS WITH T AND Y-T AS THE FIRST AND SECOND. MUST BE IN THIS ORDER.
%                 %THIS FLIP IS BECAUSE THE OPTIMAL QUANTUM INTERPOLATION FLIPS ACROSS THE MIDDLE
%                     end
% 
%                     number_mats = cell2mat(Instruction(2:3));
% 
%                     if iL == 1
%                         top_num = number_mats(1:loop_starts(iL),:);
%                         top_let = Instruction{5}(1:loop_starts(iL),:);
%                     else
%                         top_num = number_mats((loop_ends(iL-1) + 2):loop_starts(iL),:);
%                         top_let = Instruction{5}((loop_ends(iL-1) + 2):loop_starts(iL),:);
%                     end
% 
%                     middle_num = number_mats((loop_starts(iL)+1):(loop_ends(iL)+1),:);
%                     middle_let = Instruction{5}((loop_starts(iL)+1):(loop_ends(iL)+1),:);
% 
%                     if iL == length(loop_starts)
%                         bottom_num = number_mats((loop_ends(iL)+2):end,:);
%                         bottom_let = Instruction{5}((loop_ends(iL)+2):end,:);
%                     else
%                         bottom_num = [];
%                         bottom_let = {};
%                     end
% 
%                     middle_num(1,2) = 0;
%                     middle_num(end,2) = 0;
% 
%                     middle_num_expand = repmat(middle_num,nn,1);
%                     middle_let_expand = repmat(middle_let,nn,1); %expand loops
% 
%                     middle_dt_added = middle_let_expand;
% 
%                     t_index = strfind(middle_let_expand,'t');
%                     iii = 0;
%                     for ii = 1:length(middle_let_expand)
%                         if t_index{ii} ~= 0
%                             iii = iii+1;
%                             middle_dt_added{ii} = regexprep(middle_let_expand{ii},'t',['(',delay_choose{iii},')']);
%                         end
%                     end
% 
%                     temp_loopmat_num = [temp_loopmat_num; top_num; middle_num_expand; bottom_num];
%                     temp_loopmat_let = [temp_loopmat_let; top_let; middle_dt_added; bottom_let];
% 
%                     %have to renumber instruction{1}, have to expand instruction{2} (no dt
%                     %adding needed), have to make all of instruction{3} = 0 except the end
%                     %value which has to equal 1, and have to set all instruction{4} = 0.
%                     %This is because we already expanded the loop.
%                 end
%                 final_Instruction{1,5} = [];
% 
%                 final_Instruction{1,1} = (0:(length(temp_loopmat_let)-1))'; %renumber first column  from 0 to end
%                 final_Instruction{1,2} = temp_loopmat_num(:,1); %bit on/off instruction, expanded
%                 final_Instruction{1,3} = temp_loopmat_num(:,2); %should be all 0s except 1 at end. I remove all of the loop instructions.
%                 final_Instruction{1,4} = repmat({'0'},length(temp_loopmat_let),1); %all 0s
%                 final_Instruction{1,5} = temp_loopmat_let; %delay times, expanded and with +dt in the appropriate locations.
% 
%                 numInstructions = length(final_Instruction{1,5});
%                 %final instruction is the expanded form of the commands for 1 bit, with the proper dt's
%                 %inserted, in the same format from the beginning. It can now be passed onto
%                 %the remainder of the function as normal, and used for quantum
%                 %interpolation.
%             end


        end

    end

