classdef AFMScanPLImages < handle
   % This will be instantiated by the Image Scan GUI at startup
   % controls the experiment to collect PL images as we scan an AFM probe
   % (e.g., magnetic tip) over the NV center.
   % these functions are used by the controls on the AFMControl GUI
   % therefore, AFMControl has access to the handle of this class instance
   
   properties
       
       DAQ;
       DAQManage;
       srs;
       AFMControlFig;
       pulseBlaster;
       trackParameters;
       imageScanHandles;

       
       % I plan to instatiate as few obj.variables in this class as
       % necessary. Mostly I will just use "get()" to obtain the current
       % values from the GUI and save in local variables in this object's
       % particular functions.
       % Here I have the duration variables for convenience in
       % ReplacePulseVariables() 
       pTime=0;
       uTime=0;
       wTime=0;
       sTime=0;
       rTime=0;
       iTime=0;
       aTime=0;
       qTime=0; % reserved for IQ time if needed later for AFM scanning
       
       esrStruct = struct([]);
       totalSequence;
       stopScan = false;
       bLaserScan = false; % whether laser follows the afm scanner
       originalCursorX_um = [];
       originalCursorY_um = [];
       
       % scan confocal and AFM positions
       tipLiftHeight_nm = [];
       numPixels = [];
       numBuffers = [];
       scanSize_nm = [];
       pulseReps = [];
       currentNSamples;
       counterData = [];
       rawSignalPlot = [];
       rawRefPlot = [];
       avgSignalPlot = [];
       avgRefPlot = [];
       
       XConfocalVoltages;
       YConfocalVoltages;
       ZConfocalVoltages;
       %XConfocalCursor_um; % these didn't need to be obj properties
       %YConfocalCursor_um; % these didn't need to be obj properties
       %ZConfocalCursor_um; % these didn't need to be obj properties
       maxConfocalValues_nm = [];
       minConfocalValues_nm = [];
       confocalVoltageTuples=[];
       XNanoscopePositions_um;
       YNanoscopePositions_um;
       XNanoscopeCenter_um; % tip at center of the current scanner field
       YNanoscopeCenter_um;
       maxNanoscopeValues_nm = [];
       minNanoscopeValues_nm = [];
       lithoPositionTuples=[];
       
       scanStartZ_nm;
       scanEndZ_nm;
       scanLineXYDir='x';
       nonScanLineValue_nm;
       
       % image data and image handles
       imageDataCurrentSig = [];
       imageDataCurrentRef = [];
       imageDataAverageSig = [];
       imageDataAverageRef = [];
       imageDataNorm = [];
       hImageCS;
       hImageCR;
       hImageAS;
       hImageAR;
       hImageN;
       numSeriesValues=1;
       seriesCounter=1;
       
       % image registration, including configuration GUI values
       hImageRegGreenFig;
       hImageRegNVPLFig;
       imageRegScanSize; % µm
       imageRegDwellTime; % sec
       imageRegPointsPerLine;
       imageRegSubPixelFactor;
       imageDataOriginalGreen = [];
       imageDataOriginalNVPL = [];
       imageDataCurrentGreen = [];
       imageDataCurrentNVPL = [];
       imageRegCheckboxNVPL=1;
       imageRegCheckboxGreen=1;
       
       imageRegNVPLCounter = 0; % increments for each cycle of image reg.
       imageRegGreenCounter = 0; % increments for each cycle of image reg.
       
       % copy of the hardcoded volts/microns is here for convenience
       UMPerV = [25.508796 25.508796 10]; % x,y,z
       VPerUM = [0.0392021638 0.0392021638 0.1];
       
   end
   
   methods
       
       function obj = AFMScanPLImages(DAQ,PulseInterpret,SRS, handles)
           
           % handle to the AFM GUI called in ImageScan 
           % this is useless though since that GUI is not opened yet = []
            obj.AFMControlFig = handles.AFMControl;
            obj.imageScanHandles = handles;
           
            %If a DAQ manager object is passed to AFMScanPLImages,
            %use that one, otherwise just initialize one from scratch
            if ~exist('DAQ', 'var')
                obj.DAQManage = DAQManager();
                obj.DAQ = obj.DAQManage.DAQ;
            else
                if isempty(DAQ)
                    obj.DAQManage = DAQManager();
                    obj.DAQ = obj.DAQManage.DAQ;
                else
                    obj.DAQ = DAQ; % most likely result, used passed arg
                end
            end
            
            % these devices already have handles, which are passed in
            obj.pulseBlaster = PulseInterpret;
            obj.srs = SRS;
            obj.trackParameters = handles.ScanControl.TrackingParameters;
            
            if isempty(obj.imageRegScanSize)
               obj.imageRegScanSize = 5.0; % µm
            end
            if isempty(obj.imageRegDwellTime)
               obj.imageRegDwellTime = 0.004; % sec 
            end
            if isempty(obj.imageRegPointsPerLine)
               obj.imageRegPointsPerLine = 50; 
            end
            if isempty(obj.imageRegSubPixelFactor)
                obj.imageRegSubPixelFactor=100;
            end
            
            % 4/19/2013. with the configuration file change this so that
            % the conversions are updated
            obj.UMPerV = [handles.configS.xScanMicronsPerVolt, ...
                            handles.configS.yScanMicronsPerVolt,...
                            handles.configS.zScanMicronsPerVolt];
            obj.VPerUM = 1./obj.UMPerV;
            
       end
       
       function setFreq(obj, centerFreq, detuning1)
            %Sets the frequency manually to the passed in value
            fopen(obj.srs);
            fprintf(obj.srs,['FREQ ', num2str(centerFreq+detuning1),' MHz']); % write to the SG384
            fclose(obj.srs);
        end
        
        function setAmp(obj, ampl)
            %Sets the RF amplitude manually to the passed in value
            fopen(obj.srs);
            %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
            fprintf(obj.srs, ['AMPR ', num2str(ampl)]); % Ntype
            fclose(obj.srs);
        end
        
        function durExpr = ReplacePulseVariables(obj, varInstr)
            % takes the 'duration' from the pulseblaster instruction
            % as variable 'varInstr' and replaces variables with values       
            durExpr = regexprep(varInstr,'p',num2str(obj.pTime));
            durExpr = regexprep(durExpr,'s',num2str(obj.sTime));
            durExpr = regexprep(durExpr,'i',num2str(obj.iTime));
            durExpr = regexprep(durExpr,'a',num2str(obj.aTime));
            durExpr = regexprep(durExpr,'r',num2str(obj.rTime));
            durExpr = regexprep(durExpr,'w',num2str(obj.wTime));
            durExpr = regexprep(durExpr,'u',num2str(obj.uTime));
            durExpr = regexprep(durExpr,'q',num2str(obj.qTime));
        end
        function durExpr2 = ReplaceLoopVariables(obj, varInstr)
            % for now this is a dummy function, we don't need loopSweep.
            % Look at SweepControl for the actual form of this function
            
            % takes the 'duration' from the pulseblaster instruction
            % as variable 'varInstr' and replaces variables with values
            currentLoopParameter = 1;
            durExpr2 = regexprep(varInstr,'n',num2str(currentLoopParameter));
        end
       
        function SetupStaticPulseSequence(obj,afmGUI)
            % set up the pulse sequence. There is no tau to sweep so all the
              % steps are done outside the main measurement loop
              
              % get the pulse parameter values form the GUI, simple naming
            obj.pTime = str2double(get(afmGUI.piTime,'String'));
            obj.uTime = str2double(get(afmGUI.depopulationTime,'String'));
            obj.wTime = str2double(get(afmGUI.preReadoutWait,'String'));
            obj.sTime = str2double(get(afmGUI.sampleWidth,'String'));
            obj.rTime = str2double(get(afmGUI.readoutTime,'String'));
            obj.iTime = str2double(get(afmGUI.initTime,'String'));    
            obj.aTime = str2double(get(afmGUI.delayTimeAOM,'String'));
            obj.qTime=0; % space reserved for IQ time if needed later
              
              INST_LONG_DELAY = 7;
              INST_CONTINUE = 0;
              INST_BRANCH = 6;
              INST_STOP = 1;
              MINPULSE = 10; % nanoseconds
              obj.esrStruct = tdfread(get(afmGUI.pulseFile, 'String'));
              [numBits, tempSize] = size(fieldnames(obj.esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
              pulseStr = cell(numBits, 1);
              pulseNum = cell(numBits, 1);
              numInstructions = zeros(1,numBits);

              for nb = 1:numBits
                tempCell = obj.pulseBlaster.loadESRPulse(eval(['obj.esrStruct.bit' num2str(nb)]));

                pulseStr{nb} = tempCell;

                [numInstructions(1,nb), ~] = size( tempCell{1});

                % prepare a numerical array for the instructions once eval'd
                pulseNum{nb} = zeros(numInstructions(1,nb),5);
              end

              for mb = 1:numBits
                  for k = 1:numInstructions(1,mb)
                      tempCell = pulseStr{mb};
                      durExpr = ReplacePulseVariables(obj, tempCell{1,5}(k)); 
                      durExprSingle = durExpr{1};
                      durExpr2 = ReplaceLoopVariables(obj, tempCell{1,4}(k)); 
                      durExprSingle2 = durExpr2{1};

                      pulseNum{mb}(k,5) = eval(durExprSingle);
                      pulseNum{mb}(k,4) = eval(durExprSingle2);
                      pulseNum{mb}(k,3) = tempCell{1,3}(k);
                      pulseNum{mb}(k,2) = tempCell{1,2}(k);
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
          
            obj.totalSequence = eval(['obj.pulseBlaster.reconcilePulses(' pulseSequenceString ')' ]);
            [totalNumInstructions, ~] = size(obj.totalSequence);
            if obj.totalSequence(totalNumInstructions,3) == INST_STOP
                obj.totalSequence(totalNumInstructions,3) = INST_BRANCH;
            end
            if obj.totalSequence(totalNumInstructions,5) < MINPULSE
                obj.totalSequence(totalNumInstructions,5) = MINPULSE;
                % in case combining the pulses somehow makes the
                % last pulse duration = 0, which is not good
            end

            fprintf('%e\t%e\t%e\t%e\t%e\n',obj.totalSequence'); %print debug
            
            % the return is obj.totalSequence
        end
        
        function updateHandles(obj, handles)
            obj.imageScanHandles = handles;
        end
        
       function PerformMagneticTipScan(obj,handlesA)
          % the bulk of the process for scanning the MFM probe while taking
          % PL data and periodically stopping the scan to track.
          
          % nicknames for the important handles/handle structures of GUI and AFMPC Nanoscope
         
          % the handles first passed to AFMScanPLImages from ImageScan are
          % not updated so it would not know the existence of NanoZ and
          % AFMControl!
          % be aware that "handlesA" here is the AFMControl handles
          
          afmGUI = handlesA;
          nanoScope = obj.imageScanHandles.NanoZ;
          nanoScopeOA = obj.imageScanHandles.NanoA;
          
          obj.hImageRegGreenFig = 11108;
          obj.hImageRegNVPLFig = 140003;
          
          startClockTime = clock;
          nowClockTime = startClockTime;
          diffClockTime = etime(nowClockTime,startClockTime);
          set(afmGUI.elapsedTimeIndicator,'String',num2str(diffClockTime));
          
          % set up the positions for scanning the AFM scanner as well as
          % the laser to follow the NV that moves with the scanner
          obj.tipLiftHeight_nm = str2double(get(afmGUI.tipLiftHeight_nm,'String'));
          obj.numPixels = str2double(get(afmGUI.numPixelsPerDim,'String'));
          obj.scanSize_nm = str2double(get(afmGUI.scanSizePerDim,'String'));
          obj.pulseReps = str2double(get(afmGUI.numRepsPerPixel,'String'));
          obj.numBuffers = str2double(get(afmGUI.numReadBuffers,'String'));
          numAvgs = str2double(get(afmGUI.numPlotAverages,'String'));
          centerFreq = str2double(get(afmGUI.freqCenterResonance,'String'));
          detuning1 = str2double(get(afmGUI.freqDetuning1,'String'));
          rfAmplitude1 = str2double(get(afmGUI.ampChan1,'String'));
          
          % X(orY)Z scan stuff 
          obj.scanStartZ_nm = str2double(get(afmGUI.scanStartZ,'String'));
          obj.scanEndZ_nm = str2double(get(afmGUI.scanEndZ,'String'));
          %-----get a list like [z1 z1 z1 z1 z1.... z2 z2 z2 z2 z2.... z3 z3 z3 z3 z3 .....]
          zPositionsXZ = linspace(obj.scanStartZ_nm,obj.scanEndZ_nm,obj.numPixels)'*ones(1,obj.numPixels);
          zPositionsXZ = reshape(zPositionsXZ',1,obj.numPixels*obj.numPixels);
          %--------------------------
          if get(afmGUI.radiobuttonXZScanAxis,'Value')==1
              obj.scanLineXYDir = 'x'; 
          end
          if get(afmGUI.radiobuttonYZScanAxis,'Value')==1
              obj.scanLineXYDir = 'y'; 
          end
          obj.nonScanLineValue_nm = str2double(get(afmGUI.nonScanFixedPosition,'String')); % distance +/- from 0 position, in nm
          
          % as with sweepControl, do the pulse loading, replacing
          % variables, and finally combining. No tau => static over loop
          fopen(obj.srs);
          fprintf(obj.srs, ['ENBL ', '0']);
          fprintf(obj.srs, ['ENBR ', '1']);
          fclose(obj.srs);
          obj.stopScan = false;
          obj.DisableGui(afmGUI); %disable the gui to protect parameters
          
          % measurement series type
          measType = 1;
          zSeries = str2num(get(afmGUI.seriesZValues,'String'));
          dSeries = str2num(get(afmGUI.seriesDetuningValues,'String'));
          obj.numSeriesValues = 1; % default is 1 value
          obj.seriesCounter = 1; % the index for saving this data separately
          if get(afmGUI.radiobuttonMeasureSingleValued,'Value')==1
                measType = 1;
                obj.numSeriesValues=1;
          end
          if get(afmGUI.radiobuttonMeasureVaryZPerPlot,'Value')==1
                measType = 2;
                obj.tipLiftHeight_nm = zSeries(1); % set first value.
                obj.numSeriesValues = max(size(zSeries));
          end
          if get(afmGUI.radiobuttonMeasureDetuningPerPixel,'Value')==1
                measType = 3;
                detuning1 = dSeries(1);
                obj.numSeriesValues = max(size(dSeries));
          end
          if get(afmGUI.radiobuttonMeasureDetuningPerPlot,'Value')==1
                measType = 4;
                detuning1 = dSeries(1);
                obj.numSeriesValues = max(size(dSeries));
          end
          if get(afmGUI.radiobuttonMeasureXZScan,'Value')==1
                measType = 5;
                obj.numSeriesValues = 1;
          end
          
          obj.rawSignalPlot = zeros(obj.numPixels*obj.numPixels,obj.numSeriesValues);
          obj.rawRefPlot = zeros(obj.numPixels*obj.numPixels,obj.numSeriesValues);
          newSliderValue=1.0;
          
          obj.setAmp(rfAmplitude1); %Set the amplitude
          obj.setFreq(centerFreq, detuning1);
          set(afmGUI.numAveragesCompleted, 'String', num2str(0)); % reset this before starting new
          set(afmGUI.stepsSinceTracking, 'String', num2str(0)); % reset this before starting new
          
          % load pulse sequence without swept tau and set values, store in obj.totalSequence
           obj.SetupStaticPulseSequence(afmGUI); 
 
            jPlot=1;
            obj.stopScan = false;
            obj.bLaserScan = get(afmGUI.checkboxLaserFollows, 'Value');
            bTrackingRefCompleted = 0;
            trackingStepCounter = 0;
            trackingReferenceCount = 0;
            trackingCompareCount = 0;
            
            % initial file columns----------
                saveToPath = get(afmGUI.saveDataPath,'String');
                saveToFile = get(afmGUI.saveDataFilename,'String');
                saveToFullPath = [saveToPath saveToFile '\'];
                if exist(saveToPath,'dir') ==0 %path does not exist?
                             mkdir(saveToPath);
                end
                if exist(saveToFullPath,'dir') ==0 %path does not exist?
                             mkdir(saveToFullPath);
                end
                fid = fopen([saveToFullPath 'NVPL' '.txt'], 'w');
                fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'cycle','pixel','rShift','cShift','rUM','cUM','corr');
                fclose(fid);
                fidg = fopen([saveToFullPath 'Green' '.txt'], 'w');
                fprintf(fidg, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'cycle','pixel','rShift','cShift','rUM','cUM','corr');
                fclose(fidg);
                fidz = fopen([saveToFullPath 'tipZlog.txt'], 'w');
                fprintf(fidz, '%s\t%s\n','pixel','Zpos_nm');
                fclose(fidz);
            %-----------------------------------
            
            % if unsuccessful abort the scan
            % this is the opening MACRO for lithography functions
            if ~nanoScope.LithoBegin()
                warndlg('The Nanoscope LithoBegin command has failed. Scan aborted');
                obj.stopScan = true;
            end
            if obj.stopScan
                return
            end
            obj.imageDataAverageSig = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
            obj.imageDataAverageRef = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
            obj.imageDataNorm = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
            
            if measType ==5
                obj.InitializeImagePlotsXZ(afmGUI);
            else
                obj.InitializeImagePlots(afmGUI); 
            end
            nanoScope.SetScanSize(obj.scanSize_nm*0.001);
            nanoScope.LithoScan(0);
            % the first Z height lift, don't attmpt tracking (=0)
            if measType ==2
                RefreshZLiftHeight(obj, afmGUI, nanoScope, nanoScopeOA, 0, measType, zSeries(1));
            else 
                RefreshZLiftHeight(obj, afmGUI, nanoScope, nanoScopeOA, 0, measType, zPositionsXZ(1));
            end
            bPlotSeriesFirstLoopDone = 0; % , first loop completed
            
            while jPlot <= numAvgs && obj.stopScan == false        
                
                if measType ==5
                    obj.InitializeLithoPLScanXZ(afmGUI, nanoScope);
                    obj.GenerateLithoRasterPositionsXZ();
                    obj.confocalVoltageTuples=...
                        obj.GenerateConfocalRasterVoltagesXZ(obj.XConfocalVoltages,obj.YConfocalVoltages);
                else
                    obj.InitializeLithoPLScan(afmGUI, nanoScope);
                    obj.GenerateLithoRasterPositions();
                    obj.confocalVoltageTuples=...
                        obj.GenerateConfocalRasterVoltages(obj.XConfocalVoltages,obj.YConfocalVoltages);
                end
                if obj.stopScan
                    return
                end
                
                % if series is Z vals, must "refresh Z" at start of plot
                % if series is detunings, must set freq at start of plot
                % don't do this on the first loop
                if (measType==2) && (bPlotSeriesFirstLoopDone==1)
                    obj.seriesCounter = obj.seriesCounter + 1;
                    obj.tipLiftHeight_nm = zSeries(obj.seriesCounter); % set first value.
                    % but in the green tip-NV image reg always use
                    % zSeries(1) as the same value of lift height
                    RefreshZLiftHeight(obj, afmGUI, nanoScope, nanoScopeOA, 1, measType, zSeries(1));
                end
                if (measType==4) && (bPlotSeriesFirstLoopDone==1)
                    obj.seriesCounter = obj.seriesCounter + 1;
                    detuning1 = dSeries(obj.seriesCounter);
                    obj.setFreq(centerFreq, detuning1);
                end
                
                set(afmGUI.pixelsDoneIndicator, 'String',[num2str(0) '/' num2str(obj.numPixels)]);
                
                for tupleIndex = 1:length(obj.lithoPositionTuples)
                 
                    % update the clock indicator
                    nowClockTime = clock;
                    diffClockTime = etime(nowClockTime,startClockTime);
                    set(afmGUI.elapsedTimeIndicator,'String',num2str(diffClockTime));
                    
                    % only get the pulse Reps slider value at start and
                    % don't update until the next step to keep calculations
                    % consistent
                    newSliderValue = get(afmGUI.sliderPulseRepsMultiplier,'Value');
                    obj.currentNSamples = obj.numBuffers*obj.pulseReps*newSliderValue + 1;
                    
                    % if it is an XZ(YZ) scan and we are at the start of a
                    % new line, then make the Z position at the updated
                    % value
                    if measType == 5
                        if (mod(tupleIndex-1,obj.numPixels)==0)
                            %obj.UpdateTipPositionXZ(tupleIndex, nanoScope, zPositionsXZ);
                              %----------------------  
                                rateXYt = 1.0; % µm/s
                                rateZt=0.2;% µm/s
                               nanoScope.LithoTranslateAbsolute(0,0,rateXYt);
                               nanoScope.LithoFeedback(1);
                               if nanoScope.LithoIsFeedbackOn()
                                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                               else
                                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                               end
                               pause(1.0);
                               % zPosList is in nm but the function takes µm
                               nanoScope.LithoMoveZ(zPositionsXZ(tupleIndex)*0.001, rateZt);
                               newZread2 = nanoScope.LithoGetSoft(2);
                               set(afmGUI.indicatorProbeZ,'String',num2str(newZread2));
                               if nanoScope.LithoIsFeedbackOn()
                                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                               else
                                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                               end
                               %-------------------------
                        end
                    end
                    %set the new position first, laser and scanner stage
                    % for XZ(YZ) scan, I have set up the tuples to be
                    % correct using these same UpdateLitho and
                    % UpdateConfocal functions
                    
                    obj.UpdateLithoPosition(tupleIndex, nanoScope);
                    %test1DutyClock = clock;
                    obj.UpdateConfocalVoltage(tupleIndex);
                    %test2DutyClock = clock;
                    %diffDutyClock = etime(test2DutyClock,test1DutyClock)
                        
                    %update indicators of positions
                    %set(afmGUI.scannerPosIndicatorX,'String',num2str(obj.lithoPositionTuples(tupleIndex,1)));
                    %set(afmGUI.scannerPosIndicatorY,'String',num2str(obj.lithoPositionTuples(tupleIndex,2)));
                    set(afmGUI.scannerPosIndicatorX,'String',num2str(nanoScope.LithoGetXPosUM()));
                    set(afmGUI.scannerPosIndicatorY,'String',num2str(nanoScope.LithoGetYPosUM()));
                    set(afmGUI.laserPosIndicatorX,'String',num2str(obj.confocalVoltageTuples(tupleIndex,1)*obj.UMPerV(1)));
                    set(afmGUI.laserPosIndicatorY,'String',num2str(obj.confocalVoltageTuples(tupleIndex,2)*obj.UMPerV(2)));
                    
                    % loop the measurement at the pixel for detuning series
                    if measType==3
                       pixelLoops = obj.numSeriesValues; 
                    else
                       pixelLoops = 1; 
                    end
                    
                    for dInd = 1:pixelLoops
                        if measType == 3 
                            obj.seriesCounter = dInd;
                            detuning1 = dSeries(obj.seriesCounter);
                            obj.setFreq(centerFreq, detuning1);
                        end
                        % start counter for PL readout
                        obj.DAQ.CreateTask('Counter');
                        counterLine = 1;
                        obj.DAQ.ConfigureCounterIn('Counter',counterLine,obj.currentNSamples);
                        obj.counterData = [];
                        obj.DAQ.StartTask('Counter');
                        pause(0.1);

                        % begin the measurement                        
                        obj.pulseBlaster.setCurrentPulse(obj.totalSequence);
                        obj.pulseBlaster.loadToPulseblaster();
                        obj.pulseBlaster.runPulse();

                        
                        set(afmGUI.text50,'BackgroundColor','green');
                        %test1DutyClock = clock;

                        while (obj.DAQ.IsTaskDone('Counter') == false && obj.stopScan == false)
                            NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                            if NSamplesAvailable > 0
                                obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                            end
                            %pause(0.1);
                        end
                        NSamplesAvailable = obj.DAQ.GetAvailableSamples('Counter');
                        if NSamplesAvailable > 0
                            obj.counterData = [obj.counterData obj.DAQ.ReadCounterBuffer('Counter',NSamplesAvailable)];
                        end
                        
                        set(afmGUI.text50,'BackgroundColor','white');
                        %test2DutyClock = clock;
                        %diffDutyClock = etime(test2DutyClock,test1DutyClock);
                        obj.counterData = diff(obj.counterData);

                        % put the new counts into kCounts/s, dividing by the
                        % correct readout time in obj.SortCounterBuffers()
                        [signalPoint refPoint] = obj.SortCounterBuffers(afmGUI);
                        % on 11/5/2012, multiply by number to correct for
                        % actual number of samples used
                        signalPoint=signalPoint/newSliderValue;
                        refPoint=refPoint/newSliderValue;
                        obj.rawSignalPlot(tupleIndex,obj.seriesCounter) = signalPoint;
                        obj.rawRefPlot(tupleIndex,obj.seriesCounter) = refPoint;

                        % print last pixel count on front panel for testing
                        set(afmGUI.signalCountIndicator,'String',num2str(signalPoint));
                        set(afmGUI.referenceCountIndicator,'String',num2str(refPoint));

                        % format the updated list of data into matrix (image) form
                        obj.FormatPLImageData(afmGUI);

                        obj.DAQ.StopTask('Counter');
                        obj.DAQ.ClearTask('Counter');
                        obj.pulseBlaster.stopPulse(); % done with current sequence
                    end
                    
                    % I want to display all the detuning data together on
                    % the current sweep plot as well:
                    if (measType==3)
                        imSigCurr = zeros(obj.numPixels,obj.numPixels);
                        imRefCurr = zeros(obj.numPixels,obj.numPixels);
                        for ddi = 1:obj.numSeriesValues
                            imSigCurr = imSigCurr + obj.imageDataCurrentSig(:,:,ddi);
                            imRefCurr = imRefCurr + obj.imageDataCurrentRef(:,:,ddi);
                        end
                        set(obj.hImageCS,'CData',imSigCurr/obj.numSeriesValues);
                        set(obj.hImageCR,'CData',imRefCurr/obj.numSeriesValues);
                    end
                    
                    if obj.stopScan
                        break; % made sure to have this AFTER stopTask on DAQ.
                    end
                    
                    % update number of pixels done in current averaging
                    set(afmGUI.pixelsDoneIndicator, 'String',[num2str(tupleIndex) '/' num2str(obj.numPixels*obj.numPixels)]);
                    
                    %%%%%%%%%%%% tracking check------------------
                    %if get(afmGUI.checkboxUseTracking,'Value')==1 
                       trackingStepCounter = trackingStepCounter + 1;
                       
                       if (bTrackingRefCompleted==0)
                          % still collecting a tracking reference the first x # steps
                          trackingReferenceCount = trackingReferenceCount + refPoint;
                          set(afmGUI.trackingRefIndicator,'String',num2str(trackingReferenceCount/trackingStepCounter));
                          
                          % if this completes the reference count, the
                          % divide by the total number of steps to make it
                          % per step
                          if (trackingStepCounter == str2num(get(afmGUI.stepwiseTracking,'String')))
                                trackingReferenceCount = trackingReferenceCount/trackingStepCounter;
                                bTrackingRefCompleted=1; % proceed
                                trackingStepCounter=0; %reset
                          end
                          
                          tempTSteps = str2num(get(afmGUI.stepsSinceTracking, 'String'));
                          set(afmGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                          
                       else
                          % done collecting ref count, collect comparison
                          trackingCompareCount = trackingCompareCount + refPoint;
                          set(afmGUI.trackingCompIndicator,'String',num2str(trackingCompareCount/trackingStepCounter));
                          if (trackingReferenceCount~=0)
                            set(afmGUI.trackingCompRefFraction,'String',num2str(trackingCompareCount/(trackingStepCounter*trackingReferenceCount)));
                          end
                          tempTSteps = str2num(get(afmGUI.stepsSinceTracking, 'String'));
                          set(afmGUI.stepsSinceTracking, 'String', num2str(tempTSteps+1));
                          if (trackingStepCounter == str2num(get(afmGUI.stepwiseTracking,'String')))
                                trackingCompareCount = trackingCompareCount/trackingStepCounter;
                                
                                if (trackingCompareCount > trackingReferenceCount*str2num(get(afmGUI.trackingCompareThreshold,'String')))
                                   % the counts haven't gone below threshold
                                   % but if this fraction is even larger
                                   % than 1.0, set a new reference count
                                   if (trackingCompareCount/trackingReferenceCount>1.0)
                                       trackingReferenceCount=trackingCompareCount;
                                       set(afmGUI.trackingRefIndicator,'String',num2str(trackingReferenceCount));
                                   end
                                   trackingCompareCount=0; %reset
                                   trackingStepCounter=0; %reset  
                                
                                else
                                    % the counts have gone below->go TRACK!
                                    trackingReferenceCount=0; %reset
                                    trackingCompareCount=0; %reset
                                    bTrackingRefCompleted=0;
                                    if measType==2
                                        obj.RefreshZLiftHeight(afmGUI, nanoScope, nanoScopeOA, 1, measType, zSeries(1));
                                    else
                                        obj.RefreshZLiftHeight(afmGUI, nanoScope, nanoScopeOA, 1, measType, zPositionsXZ(tupleIndex));
                                    end
                                    set(afmGUI.stepsSinceTracking, 'String', num2str(0));
                                    
                                    % need to reinit the confocal voltages
                                    % since the cursor moved.
                                    cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
                                    cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String'));
                                    
                                    if measType==5
                                        [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
                                            obj.InitializeConfocalVoltagesXZ(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
                                        obj.confocalVoltageTuples=...
                                            obj.GenerateConfocalRasterVoltagesXZ(obj.XConfocalVoltages,obj.YConfocalVoltages);
                                    else  
                                        [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
                                            obj.InitializeConfocalVoltages(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
                                        obj.confocalVoltageTuples=...
                                            obj.GenerateConfocalRasterVoltages(obj.XConfocalVoltages,obj.YConfocalVoltages);
                                    end
                                    trackingStepCounter=0;
                                end
                          end
                       end
                   % end
                    
                    %--------------------------------------------
                    % do data saving at the end of each line for better
                    % frequency, especially for long per-pixel measurements
                    if (mod(tupleIndex,obj.numPixels)==0)
                        % update the averaged plots images
                        % this "Scaled norm" is a temporary solution to the axes
                        % scaling, since the norm is between 0 and 1, scale it up
                        % to the range of values in the reference matrix
                        lineNum = floor(tupleIndex/obj.numPixels);

                        scaledNorm = zeros(obj.numPixels,obj.numPixels);
                        if (measType==1) || (measType==2) || (measType==4) || (measType==5)
                            obj.imageDataAverageSig(lineNum,:,obj.seriesCounter) = (obj.imageDataAverageSig(lineNum,:,obj.seriesCounter).*(jPlot-1)+obj.imageDataCurrentSig(lineNum,:,obj.seriesCounter))/jPlot;
                            obj.imageDataAverageRef(lineNum,:,obj.seriesCounter) = (obj.imageDataAverageRef(lineNum,:,obj.seriesCounter).*(jPlot-1)+obj.imageDataCurrentRef(lineNum,:,obj.seriesCounter))/jPlot;
                            obj.imageDataNorm(lineNum,:,obj.seriesCounter) = (obj.imageDataNorm(lineNum,:,obj.seriesCounter).*(jPlot-1) + obj.imageDataCurrentSig(lineNum,:,obj.seriesCounter)./obj.imageDataCurrentRef(lineNum,:,obj.seriesCounter))/jPlot;

                            scaledNorm = obj.imageDataNorm(:,:,obj.seriesCounter).*mean(mean(obj.imageDataAverageRef(1:lineNum,:,obj.seriesCounter)));
                            
                            %-----new 08/07/2013 for scaling
                            try
                            indNonZero = find(obj.imageDataAverageSig(:,:,obj.seriesCounter));
                            indZero = find(obj.imageDataAverageSig(:,:,obj.seriesCounter)==0);
                            minElem = min(min(obj.imageDataAverageSig(indNonZero)));
                            obj.imageDataAverageSig(indZero) = minElem;
                            indNonZero = find(obj.imageDataAverageRef(:,:,obj.seriesCounter));
                            indZero = find(obj.imageDataAverageRef(:,:,obj.seriesCounter)==0);
                            minElem = min(min(obj.imageDataAverageRef(indNonZero)));
                            obj.imageDataAverageRef(indZero) = minElem;
                            indNonZero = find(scaledNorm(:,:));
                            indZero = find(scaledNorm(:,:)==0);
                            minElem = min(min(scaledNorm(indNonZero)));
                            scaledNorm(indZero) = minElem;
                            catch
                            end
                            %----------------
                            
                            set(obj.hImageAS,'CData',obj.imageDataAverageSig(:,:,obj.seriesCounter));
                            set(obj.hImageAR,'CData',obj.imageDataAverageRef(:,:,obj.seriesCounter));
                            set(obj.hImageN,'CData',scaledNorm);
                        end

                        % in the case of multiple plots, display a superposition of
                        % all of them (that is measType=3)
                        if (measType ==3)
                            obj.imageDataAverageSig(lineNum,:,:) = (obj.imageDataAverageSig(lineNum,:,:).*(jPlot-1)+obj.imageDataCurrentSig(lineNum,:,:))/jPlot;
                            obj.imageDataAverageRef(lineNum,:,:) = (obj.imageDataAverageRef(lineNum,:,:).*(jPlot-1)+obj.imageDataCurrentRef(lineNum,:,:))/jPlot;
                            obj.imageDataNorm(lineNum,:,:) = (obj.imageDataNorm(lineNum,:,:).*(jPlot-1) + obj.imageDataCurrentSig(lineNum,:,:)./obj.imageDataCurrentRef(lineNum,:,:))/jPlot;

                            imSigTotal = zeros(obj.numPixels,obj.numPixels);
                            imRefTotal = zeros(obj.numPixels,obj.numPixels);
                            for di = 1:obj.numSeriesValues
                                scaledNorm = scaledNorm+(obj.imageDataNorm(:,:,di)*mean(mean(obj.imageDataAverageRef(1:lineNum,:,di))));
                                imSigTotal = imSigTotal + obj.imageDataAverageSig(:,:,di);
                                imRefTotal = imRefTotal + obj.imageDataAverageRef(:,:,di);
                            end
                            set(obj.hImageAS,'CData',imSigTotal / obj.numSeriesValues);
                            set(obj.hImageAR,'CData',imRefTotal / obj.numSeriesValues);
                            set(obj.hImageN,'CData',scaledNorm / obj.numSeriesValues);
                        end

                        % save copies of the single "Sweep" of sig and ref plots,
                        % as well as the current norm for convenience of plotting
                        switch(measType)
                            case 1
                                obj.SavePLImageData(afmGUI);
                            case 2
                                obj.SavePLImageDataZSeries(afmGUI, obj.tipLiftHeight_nm);
                            case 3
                                % save a file for each detuning value
                                obj.seriesCounter = 0;
                                for dd=dSeries
                                    obj.seriesCounter = obj.seriesCounter + 1;
                                    obj.SavePLImageDataDetuningSeries(afmGUI, dd);
                                end
                            case 4 
                                obj.SavePLImageDataDetuningSeries(afmGUI, detuning1);
                            case 5
                                obj.SavePLImageData(afmGUI);
                        end
                    end % end of the line end saving and data
                    %---------
                    
                end  % end loop through all pixels (tuples)
                
                % update number of averages completed
                set(afmGUI.numAveragesCompleted,'String',num2str(jPlot));
                
                % after saving data, stop scan, 
                if obj.stopScan
                    break; 
                end
                
                % update jPlot counter
                % if ZPlotSeries or detuningPlotSeries, don't update until
                % the series is finished. 
                if (measType==2) || (measType==4)
                    if obj.seriesCounter == obj.numSeriesValues
                        jPlot = jPlot + 1;
                        obj.seriesCounter=0; % reset
                    end
                    
                    if (bPlotSeriesFirstLoopDone==0)
                        bPlotSeriesFirstLoopDone=1;
                    end
                else
                    jPlot = jPlot + 1;
                end   
                    
            end % end loop through all plot averages
            
            % finishing scan cleanup
            nanoScope.LithoCenterXY();
            nanoScope.LithoEnd();
            
            % setting scan size to a small (~5-20nm) to be relatively
            % "Stationary" while being able to close the Litho loop
            nanoScope.SetScanSize(0.001);
            %-------------
            obj.pulseBlaster.stopPulse();
            fopen(obj.srs);
            fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
            fclose(obj.srs);
            obj.EnableGui(afmGUI);
            obj.stopScan = false;
  
       end
       
       function UpdateScannerOffsets(obj, aGUI, nanoScopeOA, xOff_nm, yOff_nm, bEndMeasure, bIncrement)
           
           % uses the Open Architecture COM to set the exposed properties
           % of the Nanoscope for the scanner offsets. These are acquired
           % from the GUI or tip tracking, but always passed in here as
           % arguments in nanometer units
           alignAngle_deg = str2double(get(aGUI.scanAngle_deg,'String'));
           
           % these 'old' values are the scan angle version from Nanoscope
           % so no need to multiply by sin, cos again.
           oldOffX_um = nanoScopeOA.get('XOffset');
           oldOffY_um = nanoScopeOA.get('YOffset');
           
           %--- rotated versions
           % rotate the new value, or inverse rotate the old
           RxOff_nm = xOff_nm*cosd(alignAngle_deg)+yOff_nm*sind(alignAngle_deg);
           RyOff_nm = -xOff_nm*sind(alignAngle_deg)+yOff_nm*cosd(alignAngle_deg);
           
           RIoldOffX_um = oldOffX_um*cosd(alignAngle_deg)-oldOffY_um*sind(alignAngle_deg);
           RIoldOffY_um = oldOffX_um*sind(alignAngle_deg)+oldOffY_um*cosd(alignAngle_deg);
           %-----------------
           
           if (bIncrement==0)
                % absolute offset values given in input arguments
                % add in the effect of scan angle 11/03/2012
                nanoScopeOA.set('XOffset',RxOff_nm*0.001);
                nanoScopeOA.set('YOffset',RyOff_nm*0.001);
           else
                % relative offset values given in input arguments, rotation        
                nanoScopeOA.set('XOffset', oldOffX_um + RxOff_nm*0.001);
                nanoScopeOA.set('YOffset', oldOffY_um + RyOff_nm*0.001);
           end
          
          % follow with the laser cursor
          XCC_um = str2double(get(obj.imageScanHandles.editPositionX,'String'));
          YCC_um = str2double(get(obj.imageScanHandles.editPositionY,'String'));
          
          % determine how much to add to X and Y if scanner moves in x,y
          % move -X scanner => move -y confocal, move -Y scanner => move -x
          % confocal
          if bEndMeasure == 0 % not the cleanup of measurement
              if (bIncrement==0)
                    % take into account old to new offset relative dist.
                    % 'old offset' is in the scan angle transformation
                    deltaXCC_um = -(yOff_nm*0.001-RIoldOffY_um);
                    deltaYCC_um = -(xOff_nm*0.001-RIoldOffX_um);
              else
                    % if relative dist. is already input as the arguments
                    deltaXCC_um = -yOff_nm*0.001;
                    deltaYCC_um = -xOff_nm*0.001;
              end   
          else                
              % in the final cleanup the offsets will have gone to zero, so
              % use the original value just before setting to zero, and
              % negate it to make the laser follow this offset move.
              deltaXCC_um = (-oldOffY_um);
              deltaYCC_um = (-oldOffX_um);  
          end
%           obj.VPerUM(1) = 1/(25.0);
%           obj.VPerUM(2) = 1/(25.0);
%            XSetNew = (XCC_um+obj.VPerUM(1)*deltaXCC_um);
%            YSetNew = (YCC_um+obj.VPerUM(2)*deltaYCC_um);
          XSetNew = (XCC_um+deltaXCC_um);
          YSetNew = (YCC_um+deltaYCC_um);
          set(obj.imageScanHandles.editPositionX, 'String', num2str(XSetNew));
          set(obj.imageScanHandles.editPositionY, 'String', num2str(YSetNew));
          obj.imageScanHandles.CursorControl.deleteManualCursor(obj.imageScanHandles);
          obj.imageScanHandles.CursorControl.createManualCursor(obj.imageScanHandles);
          % 9-17-12, 9-18-12: again, updateVoltage takes in
          % the position in microns and will convert
          obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 1, XSetNew);
          obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 2, YSetNew);
          
          % finally, update the GUI indicators
          % 11/03/2012-11/04/2012 - add the cosine, sine parts to show
          % different offset values (effective X,Y) compared to Nanoscope
          % GUI values
          readOffX_um = nanoScopeOA.get('XOffset');
          readOffY_um = nanoScopeOA.get('YOffset');
          RIreadOffX_um = readOffX_um*cosd(alignAngle_deg)-readOffY_um*sind(alignAngle_deg);
          RIreadOffY_um = readOffX_um*sind(alignAngle_deg)+readOffY_um*cosd(alignAngle_deg);
          set(aGUI.scannerOffsetIndicatorX,'String',num2str(RIreadOffX_um));
          set(aGUI.scannerOffsetIndicatorY,'String',num2str(RIreadOffY_um));
       end
       
       function UpdateOnlyIndicatorsScannerOffsets(obj, aGUI, nanoScopeOA)
          % just read the scanner offsets and set the GUI indicators
           
          alignAngle_deg = str2double(get(aGUI.scanAngle_deg,'String'));
          readOffX_um = nanoScopeOA.get('XOffset');
          readOffY_um = nanoScopeOA.get('YOffset');
          RIreadOffX_um = readOffX_um*cosd(alignAngle_deg)-readOffY_um*sind(alignAngle_deg);
          RIreadOffY_um = readOffX_um*sind(alignAngle_deg)+readOffY_um*cosd(alignAngle_deg);
          set(aGUI.scannerOffsetIndicatorX,'String',num2str(RIreadOffX_um));
          set(aGUI.scannerOffsetIndicatorY,'String',num2str(RIreadOffY_um));
       end
       
       function PerformTrackingSequence(obj, afmGUI)
           if (get(afmGUI.checkboxUseTracking, 'Value'))==1
                    obj.DAQ.ClearTask('RunningCounter');
                    obj.DAQ.ClearTask('RunningPulseTrain');
                    obj.imageScanHandles.StateControl.changeToTrackingState(obj.imageScanHandles, true);
                    
                    %Re-initialize the daq to just acquire data normally
                    trackClockTimeStep=5000; %in microseconds.......
                    trackClockDutyCycle=0.5;
                    trackNsamples=2;
                    obj.DAQ.CreateTask('RunningPulseTrain');
                    clockFrequency = 1/trackClockTimeStep;
                    clockFrequency = clockFrequency*(10^6);
                    clockLine = 1;
                    obj.DAQ.ConfigureClockOut('RunningPulseTrain', clockLine,clockFrequency,trackClockDutyCycle);

                    %set counter to save a sample at each position(voltage pair)
                    %visited
                    obj.DAQ.CreateTask('RunningCounter');
                    counterLine = 1;
                    obj.DAQ.ConfigureCounterIn('RunningCounter',counterLine,trackNsamples);
            end
       end
       
       function TipNVImageRegistration(obj, afmGUI, nanoScopeOA, bOriginalImage, bGreenImage, measureType)
          
           % the sequence of steps here I described in Alice OneNote
           % "MATLAB: Image Registration" note in the mag-gradient AFM tab
           %MAKE SURE THAT THE SCANNER IS CENTERED, PROBABLY BEFORE CALLING
           %THIS FUNCTION
           
           % params of the Image Reg. scan are configured in
           % ConfigureImageRegistration popup GUI.
%            imageRegScanSize; % µm
%            imageRegDwellTime; % sec
%            imageRegPointsPerLine;
%             imageRegSubPixelFactor;
            % 80x80 scan at 0.004sec/pixel takes about 25.6 seconds
           
           % I decided we will always scan around the current laser cursor
           % position.
           cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
           cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String')); 
            
           cursOff = zeros(1,2);
           irCounter = 0;
           irSaveStr = [];
           irCorrected = 0; % set to false on default
           if (bGreenImage==1)
                %change the filter from PL imaging to green light imaging
                obj.imageScanHandles.FilterWheel2.goToFilter(obj.imageScanHandles, 2);
                cursOff(1) = cursorInX ;%+2.5 ;%-1.5;
                cursOff(2) = cursorInY ;%+ 1.5;%+3.0;
                obj.imageRegGreenCounter = obj.imageRegGreenCounter+1;
                irCounter=obj.imageRegGreenCounter;
                irSaveStr = 'Green';
           else
                % otherwise, we are collecting an NV PL image
                obj.imageScanHandles.FilterWheel2.goToFilter(obj.imageScanHandles, 1);
                cursOff(1) = cursorInX;
                cursOff(2) = cursorInY;
                obj.imageRegNVPLCounter = obj.imageRegNVPLCounter+1;
                irCounter=obj.imageRegNVPLCounter;
                irSaveStr = 'NVPL';
           end
           
           if bOriginalImage==1
               % if starting the measurement, this position is original
               obj.originalCursorX_um = cursorInX;
               obj.originalCursorY_um = cursorInY;
           end
           
           % use the offset cursor for making the images BUT NOT FOR
           % RESPONDING TO IMAGE REG. response should be from the current
           % non-offset cursor.
           
           % initialize the (larger than AFM scan) confocal voltages
           % image reg scan Parameter is in um, and the argument for scan
           % size takes nm
           [regVoltagesX regVoltagesY] =...
                obj.InitializeConfocalVoltages(obj.imageRegScanSize*1000, cursOff(1), cursOff(2), obj.imageRegPointsPerLine );
           regVoltageTuples=obj.GenerateConfocalRasterVoltages(regVoltagesX,regVoltagesY);
           
           % do the scan
           Na = obj.imageRegPointsPerLine;
           regNSamples = Na*Na + 1;
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
           if obj.stopScan == false
           %because of pause(.3), we need to check if externally stopped
               obj.DAQ.StartTask('PulseTrain');
           end
           % scan start done. now loop until all samples are acquired
           while (obj.stopScan == false) && (obj.DAQ.IsTaskDone('Counter') == false)
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
           regScanData = reshape(regScanData,Na,Na);
           regScanData(:,2:2:end) = flipud(regScanData(:,2:2:end));
           regScanDataTranspose = regScanData';
           %transpose ' and save to correct image matrix
           if (bOriginalImage==1)
              if (bGreenImage==1)
                  obj.imageDataOriginalGreen=regScanDataTranspose; 
                  obj.imageDataCurrentGreen=regScanDataTranspose;
              else
                  obj.imageDataOriginalNVPL=regScanDataTranspose;
                  obj.imageDataCurrentNVPL=regScanDataTranspose;
              end
              fInImage = regScanDataTranspose;
              gInImage = regScanDataTranspose;
           else
              if (bGreenImage==1)
                  obj.imageDataCurrentGreen=regScanDataTranspose;
                  fInImage = obj.imageDataOriginalGreen;
                  gInImage =  obj.imageDataCurrentGreen;
              else
                  obj.imageDataCurrentNVPL=regScanDataTranspose;
                  fInImage = obj.imageDataOriginalNVPL;
                  gInImage =  obj.imageDataCurrentNVPL;
              end
           end
           
           % perform the registration 
           [outRegValues GOutRegImage] = dftregistration(fft2(fInImage),fft2(gInImage),obj.imageRegSubPixelFactor);
           display(outRegValues),
           
           % decided not to show the image until it is done, like tracking.
           % popup a figure to set it to the current figure
           if (bGreenImage==1)
               figReg = figure(obj.hImageRegGreenFig);
               set(gcf,'Name','Green Image Registration');
               tempFigPos = get(gcf,'Position'); % set a reasonable size for the figure, but don't reset position
               set(gcf,'Position',[tempFigPos(1) tempFigPos(2) 804 224]);
               set(gcf,'ToolBar','none');
           else
               figReg = figure(obj.hImageRegNVPLFig);
               set(gcf,'Name','NV PL Image Registration');
               tempFigPos = get(gcf,'Position');
               set(gcf,'Position',[tempFigPos(1) tempFigPos(2) 804 224]);
               set(gcf,'ToolBar','none');
           end
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
           
           % use the outRegValues to adjust the scanner offsets, laser..
           netRowShift = outRegValues(3); % in fractional pixels
           netColShift = outRegValues(4); % in fractional pixels
           
           % convert fractional pixels to µm
           % make sure I know which direction 
           % a column shift in the example looks like X axis.
           % it also looks like a left shift is -col shift.
           rowShift_um = netRowShift*obj.imageRegScanSize/obj.imageRegPointsPerLine
           colShift_um = netColShift*obj.imageRegScanSize/obj.imageRegPointsPerLine
           
           % depending on green or NVPL, make appropriate adjustments to
           % hardware if this is not the Original image being obtained
           if (bOriginalImage==0)
              if (bGreenImage==0)
                    % correct for the laser-NV offset by moving laser. 
                    newCX = cursorInX-colShift_um;
                    newCY = cursorInY-rowShift_um;
                    set(obj.imageScanHandles.editPositionX, 'String', num2str(newCX));
                    set(obj.imageScanHandles.editPositionY, 'String', num2str(newCY));
                    obj.imageScanHandles.CursorControl.deleteManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.createManualCursor(obj.imageScanHandles);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 1, newCX);
                    obj.imageScanHandles.CursorControl.updateVoltage(obj.imageScanHandles, 2, newCY);
                    irCorrected=1; % set true, hardware correction done
                    
                    % need to reinit the confocal voltages
                    % since the cursor moved.
                    
                    cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
                    cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String'));
                    if (measureType==5)
                        [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
                                obj.InitializeConfocalVoltagesXZ(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
                        obj.confocalVoltageTuples=...
                                obj.GenerateConfocalRasterVoltagesXZ(obj.XConfocalVoltages,obj.YConfocalVoltages);
                    else
                        [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
                                obj.InitializeConfocalVoltages(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
                        obj.confocalVoltageTuples=...
                                obj.GenerateConfocalRasterVoltages(obj.XConfocalVoltages,obj.YConfocalVoltages);
                    end
                    
              else
                  % correct for the tip-(laserNV) offset by moving the
                  % scannerOffset together with the laser
                  % final argument =1 means increment instead of absolute
                  delX_nm = rowShift_um*1000; 
                  delY_nm = colShift_um*1000;
                  
                  % added to fakely change offsets if too big
                  if delX_nm > 0
                      delX_nm = 0;
                  end
                  if delX_nm < 0
                      delX_nm = 0;
                  end
                  if delY_nm > 0
                      delY_nm = 0;
                  end
                  if delY_nm < 0
                      delY_nm = 0;
                  end
                  
                  obj.UpdateScannerOffsets(afmGUI, nanoScopeOA, delX_nm, delY_nm, 0, 1);
                  irCorrected=0; % set true, hardware correction done
              end
           end
           
           % append the data to the files in same measurement directory
           pixelsNDone = str2num(get(afmGUI.pixelsDoneIndicator,'String'));
           avgsNDone = str2num(get(afmGUI.numAveragesCompleted,'String'));
           totalPixNDone = pixelsNDone*obj.numPixels + avgsNDone*(obj.numPixels)^2;
           saveToPath = get(afmGUI.saveDataPath,'String');
           saveToFile = get(afmGUI.saveDataFilename,'String');
           saveToFullPath = [saveToPath saveToFile '\'];
           if exist(saveToPath,'dir') ==0 %path does not exist?
                        mkdir(saveToPath);
           end
           if exist(saveToFullPath,'dir') ==0 %path does not exist?
                        mkdir(saveToFullPath);
           end
           fid = fopen([saveToFullPath irSaveStr '.txt'], 'a');
           %fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'cycle','pixel','rShift','cShift','rUM','cUM','corr');
           fprintf(fid, '%e\t%e\t%e\t%e\t%e\t%e\t%e\n', [irCounter; totalPixNDone; netRowShift; netColShift; rowShift_um; colShift_um; irCorrected]);
           fclose(fid);
           
           % at the end we always reset to the longpass filter
           % but I decided to put this external to the function to make the
           % first thing done stopping the scanner.
          
       end
       
       function RefreshZLiftHeight(obj, afmGUI, nanoScope, nanoScopeOA, bTryTrack, measureType, altZ)
           % the sample to tip height will inevitably drift off setpoint
           % periodically, or at end of each image scan, effectively bring
           % the tip back into the engage position and then move it back to
           % the specified lift height.
           % this function could be the only place that moves the z piezo
           % manually (ie, no feedback) to simplify keeping track of how the tip is being
           % moved in Z
           
           % LithoBegin must be on when the function is called.
           % do the scan, to turn on feedback, and set the scan size to be
           % very small. Or perhaps turn on Feedback with LithoFeedback(1)
           % so as not to scan at all but have the tip go to the surface.
           rateZ = 0.2; % used to be 2.0 µm/sec!!
           rateXY = 1.0; % µm/s
           %11/05/2012  -trying not to set scan size except at beginning 
           %nanoScope.SetScanSize(0.005); % small ~5 nm scan
           %nanoScope.LithoScan(1);
           nanoScope.LithoFeedback(1);
           pause(2.0);
           if (get(afmGUI.checkboxUseTracking, 'Value'))==1
                
                nanoScope.LithoTranslateAbsolute(0,0,rateXY);
                if nanoScope.LithoIsFeedbackOn()
                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                else
                    set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                end
                set(afmGUI.indicatorProbeZ,'String',num2str(nanoScope.LithoGetSoft(2)));
                % wait a very short time for the tip to go to feedback position.
                %nanoScope.LithoFeedback(1);
                if (bTryTrack==1)
                    obj.PerformTrackingSequence(afmGUI);
                end
                
                tstep = 0.5;
                tic
                while toc < tstep
                    % as used in SweepControl_standalone
                    %This method of waiting is used because it is far
                    %more accurate if nothing is happening in the
                    %background, but also can be interrupted.
                end
           
                %nanoScope.LithoScan(0);
                % (distance [µm], rate [µm/s])
                % before image registration it is good for the scanner to be
                % centered so the NV is in the original location.
                % but I centered the scanner above already in the case that I
                % don't change the scan size, just the scan feedback on/off;
                %nanoScope.LithoCenterXY();
                
           end
           %nanoScope.LithoCenterXY();
           nanoScope.LithoTranslateAbsolute(0,0,rateXY);
           nanoScope.LithoFeedback(0); % feedback off
           if nanoScope.LithoIsFeedbackOn()
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
           else
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
           end
           
           % after centering and rough 3D tracking, ready for the tipNV
           % image registration, first NV PL then GreenTip
           % I'll assume the "try track =false" for now means
           % bOriginalImage==true, since I only use it at start measurement
           
           if (get(afmGUI.checkboxUseImageReg, 'Value'))==1 
                % NVPL 
                if (obj.imageRegCheckboxNVPL==1)
                    nanoScope.LithoFeedback(1);
                    pause(2.0);
                    nanoScope.LithoFeedback(0); % delete
                    set(afmGUI.indicatorProbeZ,'String',num2str(nanoScope.LithoGetSoft(2)));
                    if nanoScope.LithoIsFeedbackOn()
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                    else
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                    end
                    pause(2.0);
                    if (measureType == 2)
                        nanoScope.LithoMoveZ(altZ*0.001, rateZ);
                    else
                        nanoScope.LithoMoveZ(obj.tipLiftHeight_nm*0.001, rateZ);
                    end
                    if nanoScope.LithoIsFeedbackOn()
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                    else
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                    end
                    set(afmGUI.indicatorProbeZ,'String',num2str(nanoScope.LithoGetSoft(2)));
                    obj.TipNVImageRegistration(afmGUI, nanoScopeOA, ~bTryTrack, 0, measureType);
                end
                
                % tip image
                if (obj.imageRegCheckboxGreen==1)
                    nanoScope.LithoFeedback(1);
                    pause(2.0);
                    if (measureType == 2)
                        nanoScope.LithoMoveZ(altZ*0.001, rateZ);
                    else
                        nanoScope.LithoMoveZ(obj.tipLiftHeight_nm*0.001, rateZ);
                    end
                    set(afmGUI.indicatorProbeZ,'String',num2str(nanoScope.LithoGetSoft(2)));
                    obj.TipNVImageRegistration(afmGUI, nanoScopeOA, ~bTryTrack, 1,measureType);
                    % reset
                    nanoScope.LithoScan(0);
                    if nanoScope.LithoIsFeedbackOn()
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                    else
                        set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                    end
                    %nanoScope.LithoCenterXY();
                    obj.imageScanHandles.FilterWheel2.goToFilter(obj.imageScanHandles, 1);
                    nanoScope.LithoTranslateAbsolute(0,0,rateXY);
                    pause(1.0);
                    nanoScope.LithoFeedback(0); % feedback off
                end
           end
           %nanoScope.SetScanSize(obj.scanSize_nm*0.001);
           % decided it is better to set scan size and stop scan BEFORE the
           % z lift because we want feedback definitely turned off.
           %if(bTryTrack==0)
                nanoScope.LithoFeedback(1);
                pause(2.0);
                nanoScope.LithoFeedback(0); % delete
                set(afmGUI.indicatorProbeZ,'String',num2str(nanoScope.LithoGetSoft(2)));
                if nanoScope.LithoIsFeedbackOn()
                     set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                else
                     set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                end
                pause(2.0);
                if (measureType==5)
                    finalZ_nm = altZ;
                else
                    finalZ_nm = obj.tipLiftHeight_nm;
                end
                nanoScope.LithoMoveZ(finalZ_nm*0.001, rateZ);
                newZread = nanoScope.LithoGetSoft(2);
                set(afmGUI.indicatorProbeZ,'String',num2str(newZread));
                if nanoScope.LithoIsFeedbackOn()
                     set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
                else
                     set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
                end
           
           
               % I would like to record in a file within the measurement folder
               % each time what the value of the Z position is after refreshed
               pixelsNDone = str2num(get(afmGUI.pixelsDoneIndicator,'String'));
               avgsNDone = str2num(get(afmGUI.numAveragesCompleted,'String'));
               totalPixNDone = pixelsNDone*obj.numPixels + avgsNDone*(obj.numPixels)^2;
               if isnan(totalPixNDone)
                  totalPixNDone = 0; 
               end
               saveToPath = get(afmGUI.saveDataPath,'String');
               saveToFile = get(afmGUI.saveDataFilename,'String');
               saveToFullPath = [saveToPath saveToFile '\'];
               if exist(saveToPath,'dir') ==0 %path does not exist?
                            mkdir(saveToPath);
               end
               if exist(saveToFullPath,'dir') ==0 %path does not exist?
                            mkdir(saveToFullPath);
               end
               fidz = fopen([saveToFullPath 'tipZlog.txt'], 'a');
               fprintf(fidz, '%e\t%e\n', [totalPixNDone; newZread]);
               fclose(fidz);
           %end
       end
       
       function SavePLImageDataDetuningSeries(obj, afmGUI, detVal)
           % save each image file (adding up to the averages) as a text file
          % with the relevant metadata
          saveToPath = get(afmGUI.saveDataPath,'String');
          saveToFile = get(afmGUI.saveDataFilename,'String');
          saveToFullPath = [saveToPath saveToFile '\'];
          saveToPathFile_sig = [ saveToFullPath saveToFile '_s_' num2str(detVal) 'MHz_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_ref= [ saveToFullPath saveToFile '_r_' num2str(detVal) 'MHz_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_norm = [ saveToFullPath saveToFile '_n_' num2str(detVal) 'MHz_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          
          if exist(saveToPath,'dir') ==0 %path does not exist?
                        mkdir(saveToPath);
          end
          if exist(saveToFullPath,'dir') ==0 %path does not exist?
                        mkdir(saveToFullPath);
          end
          
          % set the data for the image file to save
          imageToSave_sig = uint16(obj.imageDataCurrentSig(:,:,obj.seriesCounter));
          imageToSave_ref = uint16(obj.imageDataCurrentRef(:,:,obj.seriesCounter));
          imageToSave_norm = uint16(10000*obj.imageDataNorm(:,:,obj.seriesCounter)); % 0 to 1 version
          
          % get the meta data to go along with the image files
          imageInfo = obj.PLImageInfo(afmGUI);
          if isempty(imageInfo) == true
            return
          end
          
          % first save the signal image file from this "sweep"
          fid = fopen(saveToPathFile_sig, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_sig, imageToSave_sig, '-append', 'delimiter', '\t');
          
          % then save the reference image file from the "sweep"
          fid = fopen(saveToPathFile_ref, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_ref, imageToSave_ref, '-append', 'delimiter', '\t');
          
          % then save the norm image file from the "sweep"
          fid = fopen(saveToPathFile_norm, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_norm, imageToSave_norm, '-append', 'delimiter', '\t');
       end
       
       function SavePLImageDataZSeries(obj, afmGUI, zVal)
          % save each image file (adding up to the averages) as a text file
          % with the relevant metadata
          saveToPath = get(afmGUI.saveDataPath,'String');
          saveToFile = get(afmGUI.saveDataFilename,'String');
          saveToFullPath = [saveToPath saveToFile '\'];
          saveToPathFile_sig = [ saveToFullPath saveToFile '_s_' num2str(zVal) 'nm_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_ref= [ saveToFullPath saveToFile '_r_' num2str(zVal) 'nm_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_norm = [ saveToFullPath saveToFile '_n_' num2str(zVal) 'nm_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          
          if exist(saveToPath,'dir') ==0 %path does not exist?
                        mkdir(saveToPath);
          end
          if exist(saveToFullPath,'dir') ==0 %path does not exist?
                        mkdir(saveToFullPath);
          end
          
          % set the data for the image file to save
          imageToSave_sig = uint16(obj.imageDataCurrentSig(:,:,obj.seriesCounter));
          imageToSave_ref = uint16(obj.imageDataCurrentRef(:,:,obj.seriesCounter));
          imageToSave_norm = uint16(10000*obj.imageDataNorm(:,:,obj.seriesCounter)); % 0 to 1 version
          
          % get the meta data to go along with the image files
          imageInfo = obj.PLImageInfo(afmGUI);
          if isempty(imageInfo) == true
            return
          end
          
          % first save the signal image file from this "sweep"
          fid = fopen(saveToPathFile_sig, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_sig, imageToSave_sig, '-append', 'delimiter', '\t');
          
          % then save the reference image file from the "sweep"
          fid = fopen(saveToPathFile_ref, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_ref, imageToSave_ref, '-append', 'delimiter', '\t');
          
          % then save the norm image file from the "sweep"
          fid = fopen(saveToPathFile_norm, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_norm, imageToSave_norm, '-append', 'delimiter', '\t');
       end
       
       function SavePLImageData(obj, afmGUI)
          % save each image file (adding up to the averages) as a text file
          % with the relevant metadata
          saveToPath = get(afmGUI.saveDataPath,'String');
          saveToFile = get(afmGUI.saveDataFilename,'String');
          saveToFullPath = [saveToPath saveToFile '\'];
          saveToPathFile_sig = [ saveToFullPath saveToFile '_sig_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_ref= [ saveToFullPath saveToFile '_ref_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          saveToPathFile_norm = [ saveToFullPath saveToFile '_norm_' get(afmGUI.numAveragesCompleted,'String') '.txt'];
          
          if exist(saveToPath,'dir') ==0 %path does not exist?
                        mkdir(saveToPath);
          end
          if exist(saveToFullPath,'dir') ==0 %path does not exist?
                        mkdir(saveToFullPath);
          end
          
          % set the data for the image file to save
          imageToSave_sig = uint16(obj.imageDataCurrentSig(:,:,obj.seriesCounter));
          imageToSave_ref = uint16(obj.imageDataCurrentRef(:,:,obj.seriesCounter));
          imageToSave_norm = uint16(10000*obj.imageDataNorm(:,:,obj.seriesCounter)); % 0 to 1 version
          
          % get the meta data to go along with the image files
          imageInfo = obj.PLImageInfo(afmGUI);
          if isempty(imageInfo) == true
            return
          end
          
          % first save the signal image file from this "sweep"
          fid = fopen(saveToPathFile_sig, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_sig, imageToSave_sig, '-append', 'delimiter', '\t');
          
          % then save the reference image file from the "sweep"
          fid = fopen(saveToPathFile_ref, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_ref, imageToSave_ref, '-append', 'delimiter', '\t');
          
          % then save the norm image file from the "sweep"
          fid = fopen(saveToPathFile_norm, 'wt');
          fprintf(fid, imageInfo.description);
          fprintf(fid, '\n\n');
          fclose(fid);
          dlmwrite(saveToPathFile_norm, imageToSave_norm, '-append', 'delimiter', '\t');
       end
       
       function imageInfo = PLImageInfo(obj,afmGUI)
           % get the description/parameters of the scan 
           
           description = '';
           description = [description 'Timestamp: ' datestr(now) ' ' sprintf('\n')];
           description = [description 'TipLiftHeight: ' ...
                    num2str(obj.tipLiftHeight_nm) ' nm $' sprintf('\n')];
           description = [description 'ScanSize: ' ...
                    num2str(obj.scanSize_nm) ' nm $' sprintf('\n')];  
           description = [description 'ScanSize: ' ...
                    num2str(obj.scanSize_nm) ' nm $' sprintf('\n')];
           description = [description 'PixelsPerDim: ' ...
                    num2str(obj.numPixels) ' $' sprintf('\n')];
           description = [description 'PulseReps: ' ...
                    num2str(obj.pulseReps) ' $' sprintf('\n')];  
           description = [description 'numReadoutBuffers: ' ...
                    num2str(obj.numBuffers) ' $' sprintf('\n')];
                
           description = [description 'pTime: ' ...
                    num2str(obj.pTime) ' ns $' sprintf('\n')];  
           description = [description 'uTime: ' ...
                    num2str(obj.uTime) ' ns $' sprintf('\n')];
           description = [description 'wTime: ' ...
                    num2str(obj.wTime) ' ns $' sprintf('\n')];
           description = [description 'zStart: ' ...
                    num2str(obj.scanStartZ_nm) ' nm $' sprintf('\n')];
           description = [description 'zEnd: ' ...
                    num2str(obj.scanEndZ_nm) ' nm $' sprintf('\n')];
           description = [description 'iTime: ' ...
                    num2str(obj.iTime) ' ns $' sprintf('\n')];
           description = [description 'aTime: ' ...
                    num2str(obj.aTime) ' ns $' sprintf('\n')];
                
           description = [description 'RFCenterFreq: ' ...
                    get(afmGUI.freqCenterResonance,'String') ' MHz $' sprintf('\n')];
           description = [description 'RFDetuning1: ' ...
                    get(afmGUI.freqDetuning1,'String') ' MHz $' sprintf('\n')];
           description = [description 'RFAmpl1: ' ...
                    get(afmGUI.ampChan1,'String') ' dbm $' sprintf('\n')]; 
           regFile = get(afmGUI.pulseFile,'String');
           regFile = regexprep(regFile,'\',':');
           description = [description 'PulseSequence: ' ...
                   regFile ' $' sprintf('\n')];
                
                % I need to use regexp to transform the '\' in the pulse
                % file to ':' because it isn't printing past 'C:'
                
           imageInfo.description = description;
           
       end
           
       function FormatPLImageData(obj, afmGUI)
           sigAux = obj.rawSignalPlot(:,obj.seriesCounter);
           refAux = obj.rawRefPlot(:,obj.seriesCounter);
           
           % reshape the one column data to a NxN matrix
           sigAux = reshape(sigAux,obj.numPixels,obj.numPixels);
           refAux = reshape(refAux,obj.numPixels,obj.numPixels);
           
           % flip every other column to account for the raster scan
           sigAux(:,2:2:end) = flipud(sigAux(:,2:2:end));
           refAux(:,2:2:end) = flipud(refAux(:,2:2:end));
           
           % this gives columns of changing x value PL, but x axis is on
           % the image of the X axis, so transpose it
           obj.imageDataCurrentSig(:,:,obj.seriesCounter) = sigAux';
           obj.imageDataCurrentRef(:,:,obj.seriesCounter) = refAux';
           
           % new on 08/07/2013
           % to keep the color scale looking good set zero-valued elements
           % to something close to the range of the other pixels
           try
           indNonZero = find(obj.imageDataCurrentSig(:,:,obj.seriesCounter));
           indZero = find(obj.imageDataCurrentSig(:,:,obj.seriesCounter)==0);
           minElem = min(min(obj.imageDataCurrentSig(indNonZero)));
           obj.imageDataCurrentSig(indZero) = minElem;
           indNonZero = find(obj.imageDataCurrentRef(:,:,obj.seriesCounter));
           indZero = find(obj.imageDataCurrentRef(:,:,obj.seriesCounter)==0);
           minElem = min(min(obj.imageDataCurrentRef(indNonZero)));
           obj.imageDataCurrentRef(indZero) = minElem;
           catch
               errorID = 1
           end
           %-------
           
           % update the image as well
           set(obj.hImageCS,'CData',obj.imageDataCurrentSig(:,:,obj.seriesCounter));
           set(obj.hImageCR,'CData',obj.imageDataCurrentRef(:,:,obj.seriesCounter));
           
           % added 11/02/2012 - color data bug fix?
          % clim1 = get(afmGUI.currentScanReferenceAxes,'CLim');
          % set(obj.hImageCS,'Clim',clim1);
          % set(obj.hImageCR,'CLim',clim1);
           
           set(obj.hImageAS,'CData',obj.imageDataAverageSig(:,:,obj.seriesCounter));
           set(obj.hImageAR,'CData',obj.imageDataAverageRef(:,:,obj.seriesCounter));
           
           % colorbar stuff
           colorbar('peer',afmGUI.currentScanReferenceAxes); % appends color bar using current colormap
           caxis(afmGUI.currentScanReferenceAxes, 'auto');
       end
       
       function [sPoint rPoint] = SortCounterBuffers(obj,afmGUI)
           % based on 1) how many counter buffers per pulse Rep (usually 2 or 4)
           % 2) whether to turn on APD count early by 50ns, checkboxes
           
            check50Sig = get(afmGUI.checkbox50nsSignalAOM_APD,'Value'); 
            check50Ref = get(afmGUI.checkbox50nsReferenceAOM_APD,'Value');
            switch(obj.numBuffers)
                case 2
                    if check50Sig == true
                        sPoint = sum(obj.counterData(1:2:end))/(obj.pulseReps*(obj.rTime-50)*1e-6);
                    else
                        sPoint = sum(obj.counterData(1:2:end))/(obj.pulseReps*(obj.rTime)*1e-6);
                    end
                    if check50Ref == true
                        rPoint = sum(obj.counterData(2:2:end))/(obj.pulseReps*(obj.rTime-50)*1e-6);
                    else
                        rPoint = sum(obj.counterData(2:2:end))/(obj.pulseReps*obj.rTime*1e-6);
                    end
                case 4
                    if check50Sig == true
                        sPoint = sum(obj.counterData(1:4:end))/(obj.pulseReps*(obj.rTime-50)*1e-6);
                    else
                        sPoint = sum(obj.counterData(1:4:end))/(obj.pulseReps*(obj.rTime)*1e-6);
                    end
                    if check50Ref == true
                        rPoint = sum(obj.counterData(3:4:end))/(obj.pulseReps*(obj.rTime-50)*1e-6);
                    else
                        rPoint = sum(obj.counterData(3:4:end))/(obj.pulseReps*obj.rTime*1e-6);
                    end   
            end
       end
       
       
       function UpdateLithoPosition(obj, currIndex, nanoScope)
           % this function moves the sample stage to the next position to
           % be ready to take PL data at a new pixel
           %LithoBegin is already activated at the start of the measurement
           tRate = 1.0; % speed in µm/second
           lx=1;
           ly=2;
           nanoScope.LithoTranslateAbsolute(obj.lithoPositionTuples(currIndex,lx),...
                                            obj.lithoPositionTuples(currIndex,ly),...
                                            tRate);
           
           % the code should pause by itself until the move is done, but
           % add a Matlab pause later if there are any issues
           
           % if LithoTranslateAbsolute (using tuple directly) for any reason
           % doesn't work well, we can get the difference between adjacent
           % tuple positions and then use LithoTranslate
           
       end
       
       function UpdateConfocalVoltage(obj, currIndex)
           % this function moves the laser spot to follow the stage
           % movement so as not to lose the NV we are focused on
           cx=1; % DAQManager AO lines
           cy=2;
           obj.DAQ.AnalogOutVoltages(cx) = obj.confocalVoltageTuples(currIndex,cx);
           obj.DAQ.WriteAnalogOutLine(cx);
           obj.DAQ.AnalogOutVoltages(cy) = obj.confocalVoltageTuples(currIndex,cy);
           obj.DAQ.WriteAnalogOutLine(cy);
       end
       
       function InitializeImagePlots(obj, afmGUI)
           obj.imageDataCurrentSig = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           obj.imageDataCurrentRef = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           % scale data (full clormap) and display as image
           % I need to edit the last argument for the colorbar range
           % I also don't want to use max/minConfocalValues since these may
           % change due to tracking the NV. Rather, get the min/max from
           % the AFM scanner position.
           
           xlim = [-obj.scanSize_nm*0.5 obj.scanSize_nm*0.5];
           ylim = [-obj.scanSize_nm*0.5 obj.scanSize_nm*0.5];
           % first make each respective axes current, then display image
           % having an output value for axes makes it "faster"
           axes(afmGUI.currentScanSignalAxes);
           obj.hImageCS = imagesc([xlim(1),xlim(2)],...
	        		[ylim(1),ylim(2)],...
            	obj.imageDataCurrentSig(:,:,1));%,caxis(afmGUI.currentScanReferenceAxes) );
            
           axes(afmGUI.currentScanReferenceAxes);
           obj.hImageCR = imagesc([xlim(1),xlim(2)],...
	        		[ylim(1),ylim(2)],...
            	obj.imageDataCurrentRef(:,:,1));%,caxis(afmGUI.currentScanReferenceAxes) );
            
           axes(afmGUI.averageScanSignalAxes);
           obj.hImageAS = imagesc([xlim(1),xlim(2)],...
	        		[ylim(1),ylim(2)],...
            	obj.imageDataAverageSig(:,:,1));%,caxis(afmGUI.currentScanReferenceAxes) );
            
           axes(afmGUI.averageScanReferenceAxes);
           obj.hImageAR = imagesc([xlim(1),xlim(2)],...
	        		[ylim(1),ylim(2)],...
            	obj.imageDataAverageRef(:,:,1));%,caxis(afmGUI.currentScanReferenceAxes) );
            
            axes(afmGUI.averageScanNormAxes);
            obj.hImageN = imagesc([xlim(1),xlim(2)],...
	        		[ylim(1),ylim(2)],...
            	obj.imageDataNorm(:,:,1) );
            
            colorbar('peer',afmGUI.currentScanReferenceAxes);
            
            title(afmGUI.currentScanSignalAxes,'Current Scan PL (signal)');
            title(afmGUI.currentScanReferenceAxes,'Current Scan PL (ref)');
            title(afmGUI.averageScanSignalAxes,'Averaged Scan PL (signal)');
            title(afmGUI.averageScanReferenceAxes,'Averaged Scan PL (ref)');
            title(afmGUI.averageScanNormAxes,'Normalized Scan PL');
            xlabel(afmGUI.currentScanSignalAxes,'');
            xlabel(afmGUI.currentScanReferenceAxes,'');
            xlabel(afmGUI.averageScanSignalAxes,'Tip x (nm)');
            xlabel(afmGUI.averageScanReferenceAxes,'Tip x (nm)');
            ylabel(afmGUI.currentScanSignalAxes,'');
            ylabel(afmGUI.currentScanReferenceAxes,'Tip y (nm)');
            ylabel(afmGUI.averageScanSignalAxes,'');
            ylabel(afmGUI.averageScanReferenceAxes,'Tip y (nm)');
            xlabel(afmGUI.averageScanNormAxes,'Tip x (nm)');
            set(afmGUI.currentScanSignalAxes,'YDir','normal');
            set(afmGUI.currentScanReferenceAxes,'YDir','normal');
            set(afmGUI.averageScanSignalAxes,'YDir','normal');
            set(afmGUI.averageScanReferenceAxes,'YDir','normal');
            set(afmGUI.averageScanNormAxes,'YDir','normal');
            colormap(pink(64));
           
       end
       
       function InitializeImagePlotsXZ(obj, afmGUI)
           obj.imageDataCurrentSig = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           obj.imageDataCurrentRef = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           % scale data (full clormap) and display as image
           % I need to edit the last argument for the colorbar range
           % I also don't want to use max/minConfocalValues since these may
           % change due to tracking the NV. Rather, get the min/max from
           % the AFM scanner position.
           
           xORylim = [-obj.scanSize_nm*0.5 obj.scanSize_nm*0.5];
           zlim = [obj.scanStartZ_nm obj.scanEndZ_nm];
           % first make each respective axes current, then display image
           % having an output value for axes makes it "faster"
           axes(afmGUI.currentScanSignalAxes);
           obj.hImageCS = imagesc([xORylim(1),xORylim(2)],...
	        		[zlim(1),zlim(2)],...
            	obj.imageDataCurrentSig(:,:,1) );
            
           axes(afmGUI.currentScanReferenceAxes);
           obj.hImageCR = imagesc([xORylim(1),xORylim(2)],...
	        		[zlim(1),zlim(2)],...
            	obj.imageDataCurrentRef(:,:,1) );
            
           axes(afmGUI.averageScanSignalAxes);
           obj.hImageAS = imagesc([xORylim(1),xORylim(2)],...
	        		[zlim(1),zlim(2)],...
            	obj.imageDataAverageSig(:,:,1) );
            
           axes(afmGUI.averageScanReferenceAxes);
           obj.hImageAR = imagesc([xORylim(1),xORylim(2)],...
	        		[zlim(1),zlim(2)],...
            	obj.imageDataAverageRef(:,:,1) );
            
            axes(afmGUI.averageScanNormAxes);
            obj.hImageN = imagesc([xORylim(1),xORylim(2)],...
	        		[zlim(1),zlim(2)],...
            	obj.imageDataNorm(:,:,1) );
            
            colorbar('peer',afmGUI.currentScanReferenceAxes);
            
            title(afmGUI.currentScanSignalAxes,'Current Scan PL (signal)');
            title(afmGUI.currentScanReferenceAxes,'Current Scan PL (ref)');
            title(afmGUI.averageScanSignalAxes,'Averaged Scan PL (signal)');
            title(afmGUI.averageScanReferenceAxes,'Averaged Scan PL (ref)');
            title(afmGUI.averageScanNormAxes,'Normalized Scan PL');
            xlabel(afmGUI.currentScanSignalAxes,'');
            xlabel(afmGUI.currentScanReferenceAxes,'');
            xlabel(afmGUI.averageScanSignalAxes,['Tip ' obj.scanLineXYDir ' (nm)']);
            xlabel(afmGUI.averageScanReferenceAxes,['Tip ' obj.scanLineXYDir ' (nm)']);
            ylabel(afmGUI.currentScanSignalAxes,'');
            ylabel(afmGUI.currentScanReferenceAxes,'Tip z (nm)');
            ylabel(afmGUI.averageScanSignalAxes,'');
            ylabel(afmGUI.averageScanReferenceAxes,'Tip z (nm)');
            xlabel(afmGUI.averageScanNormAxes,['Tip ' obj.scanLineXYDir ' (nm)']);
            set(afmGUI.currentScanSignalAxes,'YDir','normal');
            set(afmGUI.currentScanReferenceAxes,'YDir','normal');
            set(afmGUI.averageScanSignalAxes,'YDir','normal');
            set(afmGUI.averageScanReferenceAxes,'YDir','normal');
            set(afmGUI.averageScanNormAxes,'YDir','normal');
            colormap(pink(64));
       end
       
       function InitializeLithoPLScan(obj, afmGUI, nanoScope)
          
           % determine the linear set of positions for the AFM scanner
           obj.InitializeLithoPositions(nanoScope); 
           
           % Initialize the confocal voltages centered on input(cursor,etc...)
           cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
           cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String'));
           
           [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
               obj.InitializeConfocalVoltages(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
           
           % set the number of count buffers to obtain
           obj.currentNSamples = obj.numBuffers*obj.pulseReps + 1;
           
           % in any series case, it will be fine to reset all data, as it
           % has already been saved to a file
           obj.imageDataCurrentSig(:,:,:) = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           obj.imageDataCurrentRef(:,:,:) = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);  
            
       end
       
       function InitializeLithoPLScanXZ(obj, afmGUI, nanoScope)
          
           % determine the linear set of positions for the AFM scanner
           obj.InitializeLithoPositionsXZ(nanoScope, obj.nonScanLineValue_nm); 
           
           % Initialize the confocal voltages centered on input(cursor,etc...)
           cursorInX = str2double(get(obj.imageScanHandles.editPositionX,'String'));
           cursorInY = str2double(get(obj.imageScanHandles.editPositionY,'String'));
           
           [obj.XConfocalVoltages, obj.YConfocalVoltages] =...
               obj.InitializeConfocalVoltagesXZ(obj.scanSize_nm, cursorInX, cursorInY,obj.numPixels );
           
           % set the number of count buffers to obtain
           obj.currentNSamples = obj.numBuffers*obj.pulseReps + 1;
           
           % in any series case, it will be fine to reset all data, as it
           % has already been saved to a file
           obj.imageDataCurrentSig(:,:,:) = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);
           obj.imageDataCurrentRef(:,:,:) = zeros(obj.numPixels,obj.numPixels,obj.numSeriesValues);  
            
       end
       
       function InitializeLithoPositions(obj, nanoScope)
           
           obj.XNanoscopeCenter_um = 0.0;
           obj.YNanoscopeCenter_um = 0.0;
           
           xlim = [(obj.XNanoscopeCenter_um - 0.5*obj.scanSize_nm*0.001)...
               (obj.XNanoscopeCenter_um + 0.5*obj.scanSize_nm*0.001)];
           ylim = [(obj.YNanoscopeCenter_um - 0.5*obj.scanSize_nm*0.001)...
               (obj.YNanoscopeCenter_um + 0.5*obj.scanSize_nm*0.001)];
           
           % perhaps do some check on if these limits are okay with scanner
           %---------->
           
           obj.minNanoscopeValues_nm(1) = xlim(1)*1000;
           obj.minNanoscopeValues_nm(2) = ylim(1)*1000;
           obj.maxNanoscopeValues_nm(1) = xlim(2)*1000;
           obj.maxNanoscopeValues_nm(2) = ylim(2)*1000;
           
           Lx = linspace(xlim(1),xlim(2),obj.numPixels);
           obj.XNanoscopePositions_um = Lx;
            
           Ly = linspace(ylim(1),ylim(2),obj.numPixels);
           obj.YNanoscopePositions_um = Ly;  
           
       end
       
       function InitializeLithoPositionsXZ(obj, nanoScope, nonScanLineValue_nm)
           
           % the X confocal direction of course is what we use on the plot,
           % but I still call X the scan line direction here because it is
           % in the "Generate" function that the flipping is done to move
           % the scanner correctly.
           
           if strcmp(obj.scanLineXYDir,'x')  
           
               obj.XNanoscopeCenter_um = 0.0;
               obj.YNanoscopeCenter_um = nonScanLineValue_nm/1000;

               xlim = [(obj.XNanoscopeCenter_um - 0.5*obj.scanSize_nm*0.001)...
                   (obj.XNanoscopeCenter_um + 0.5*obj.scanSize_nm*0.001)];
               ylim = [obj.YNanoscopeCenter_um obj.YNanoscopeCenter_um];
           else
               obj.XNanoscopeCenter_um = nonScanLineValue_nm/1000;
               obj.YNanoscopeCenter_um = 0.0;

               xlim = [obj.XNanoscopeCenter_um obj.XNanoscopeCenter_um];
               ylim = [(obj.YNanoscopeCenter_um - 0.5*obj.scanSize_nm*0.001)...
                   (obj.YNanoscopeCenter_um + 0.5*obj.scanSize_nm*0.001)];
           end

               % perhaps do some check on if these limits are okay with scanner
               %---------->

               obj.minNanoscopeValues_nm(1) = xlim(1)*1000;
               obj.minNanoscopeValues_nm(2) = ylim(1)*1000;
               obj.maxNanoscopeValues_nm(1) = xlim(2)*1000;
               obj.maxNanoscopeValues_nm(2) = ylim(2)*1000;

               Lx = linspace(xlim(1),xlim(2),obj.numPixels);
               obj.XNanoscopePositions_um = Lx;

               Ly = linspace(ylim(1),ylim(2),obj.numPixels);
               obj.YNanoscopePositions_um = Ly;  
           
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
            
            % if no laser following, the make all the voltages the center
            if obj.bLaserScan ==false
                confocalVoltagesOutX=confocalVoltagesOutX*0 + confocalCenterInX_um*obj.VPerUM(dimX);
                confocalVoltagesOutY=confocalVoltagesOutY*0 + confocalCenterInY_um*obj.VPerUM(dimY);
            end
       end
       
       function [confocalVoltagesOutX confocalVoltagesOutY] = InitializeConfocalVoltagesXZ(obj, sizeDimIn_nm, confocalCenterInX_um, confocalCenterInY_um, pixelsPerDim)
           
           % first get the cursor position to start with in [µm]
           % recall "handles" refers to ImageScan list of handles as that
           % is the function instantiating this AFMScanPLImages
           
           % check that a full scan box around the cursor will not cause
           % the required voltage to exceed the imposed AnalogOut limts
           
           if strcmp(obj.scanLineXYDir,'x')
                xlim = [(confocalCenterInX_um - 0.5*sizeDimIn_nm*0.001)...
                    (confocalCenterInX_um + 0.5*sizeDimIn_nm*0.001)];
                ylim = (confocalCenterInY_um + obj.nonScanLineValue_nm/1000)*[1 1];
           else
                xlim = (confocalCenterInX_um + obj.nonScanLineValue_nm/1000)*[1 1];
                ylim = [(confocalCenterInY_um - 0.5*sizeDimIn_nm*0.001)...
                    (confocalCenterInY_um + 0.5*sizeDimIn_nm*0.001)];
           end
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
            
            % if no laser following, the make all the voltages the center
            if obj.bLaserScan ==false
                confocalVoltagesOutX=confocalVoltagesOutX*0 + confocalCenterInX_um*obj.VPerUM(dimX);
                confocalVoltagesOutY=confocalVoltagesOutY*0 + confocalCenterInY_um*obj.VPerUM(dimY);
            end
       end
       
       function GenerateLithoRasterPositions(obj)
           % make the position tuples in the raster scanning order
          % this is for the scanning stage translation
          
          % all typical scans should be 2D, X and Y
          La = obj.XNanoscopePositions_um;
          Lb = obj.YNanoscopePositions_um;
          % reverse row for matching to the confocal physical axes.
          %La = fliplr(La);
          
          %store position Tuples where Row# gives B position, Col#
          %gives A
          %position, and Page# is the voltage for A or B galvos
          PositionMatrix = zeros(length(La),length(Lb),2);
          
          %generate X voltages that vary in Row# but not Col#
            PositionMatrix(:,:,1) = La(:) * ones(1,length(Lb));
            %generate Y voltages that vary in Col# but not Row#
            PositionMatrix(:,:,2) = ones(length(La),1)*Lb;
            %Reverse every other X column, so each scanning position is
            %close to the next position.
            PositionMatrix(:,2:2:end,1)=flipdim(PositionMatrix(:,2:2:end,1),1);
            %z 2:2:end
            
            %reshape into an ordered list of Tuples, first column is X voltage,
            %second is Y. n rows by 2 columns.
            obj.lithoPositionTuples = reshape(PositionMatrix,[],2,1);
           % tempS = obj.lithoPositionTuples
            
            % this step is only taken in the litho positions in order to
            % match the physical positions with the laser spot. I need to
            % flipud and fliplr. See Bryan's notebook #3 pages 94-95 for
            % the idea behind the transformation
            obj.lithoPositionTuples = fliplr(obj.lithoPositionTuples);
            %tempLR = obj.lithoPositionTuples
            obj.lithoPositionTuples(:,2) = flipud(obj.lithoPositionTuples(:,2));
            %tempUD = obj.lithoPositionTuples
       end
       
       function GenerateLithoRasterPositionsXZ(obj)
           % make the position tuples in the raster scanning order
          % this is for the scanning stage translation
          
          % all typical scans should be 2D, X and Y
          if  strcmp(obj.scanLineXYDir,'x')
              La = obj.XNanoscopePositions_um; % fast scan axis
              Lb = obj.YNanoscopePositions_um; % slow(fixed) axis
          else
              La = obj.YNanoscopePositions_um; % fast scan axis
              Lb = obj.XNanoscopePositions_um; % slow(fixed) axis
          end
            % reverse row for matching to the confocal physical axes.
          %La = fliplr(La);
          
          %store position Tuples where Row# gives B position, Col#
          %gives A
          %position, and Page# is the voltage for A or B galvos
          PositionMatrix = zeros(length(La),length(Lb),2);
          
          %generate X voltages that vary in Row# but not Col#
            PositionMatrix(:,:,1) = La(:) * ones(1,length(Lb));
            %generate Y voltages that vary in Col# but not Row#
            PositionMatrix(:,:,2) = ones(length(La),1)*Lb;
            %Reverse every other X column, so each scanning position is
            %close to the next position.
            PositionMatrix(:,2:2:end,1)=flipdim(PositionMatrix(:,2:2:end,1),1);
            %z 2:2:end
            
            %reshape into an ordered list of Tuples, first column is X voltage,
            %second is Y. n rows by 2 columns.
            obj.lithoPositionTuples = reshape(PositionMatrix,[],2,1);
           % tempS = obj.lithoPositionTuples
            
            % this step is only taken in the litho positions in order to
            % match the physical positions with the laser spot. I need to
            % flipud and fliplr. See Bryan's notebook #3 pages 94-95 for
            % the idea behind the transformation
            obj.lithoPositionTuples = fliplr(obj.lithoPositionTuples);
            %tempLR = obj.lithoPositionTuples
            obj.lithoPositionTuples(:,2) = flipud(obj.lithoPositionTuples(:,2));
            %tempUD = obj.lithoPositionTuples
            if strcmp(obj.scanLineXYDir,'y')
                % slow scan axis is X now (fixed) while Y is fast scan axis
                % but i still need to flip these rows back due to initial
                % switch at the top of this function for scanLineXYDir=y
                obj.lithoPositionTuples = fliplr(obj.lithoPositionTuples);
            end
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
       
       function [confocalTuplesOutV] = GenerateConfocalRasterVoltagesXZ(obj, confocalVoltagesInX, confocalVoltagesInY)
          % make the voltage tuples in the raster scanning order
          % this is for the galvo
          
          % all typical scans should be 2D, X and Y
          if  strcmp(obj.scanLineXYDir,'x')
             Va = confocalVoltagesInX; % fast scan axis
             Vb = confocalVoltagesInY; % slow(fixed) axis
          else
             Va = confocalVoltagesInY; % fast scan axis
             Vb = confocalVoltagesInX; % slow(fixed) axis
          end
          
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
            if strcmp(obj.scanLineXYDir,'y')
                % slow scan axis is X now (fixed) while Y is fast scan axis
                % but i still need to flip these rows back due to initial
                % switch at the top of this function for scanLineXYDir=y
                confocalTuplesOutV = fliplr(confocalTuplesOutV);
            end
       end
       
       function UpdateTipPositionXZ(pixelIndex, nanoScope, zPosList_nm)
           % this is for updating the Z position, besides the RefreshZ,
           % when we are scanning in a XZ or YZ way, where Z is the slow
           % scan axis and either X or Y position is fixed.
           
           % to be consistent the tip should lift from the same position
           % each time, which should be the 0,0 position of the XY scanner
           % (even if this 0,0 point is not a position in the scan, because
           % RefreshZ always uses 0,0 and so it is most consistent).
           rateXY = 1.0; % µm/s
           nanoScope.LithoTranslateAbsolute(0,0,rateXY);
           nanoScope.LithoFeedback(1);
           if nanoScope.LithoIsFeedbackOn()
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
           else
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
           end
           pause(1.0);
           % zPosList is in nm but the function takes µm
           nanoScope.LithoMoveZ(zPosList_nm(pixelIndex)*0.001, rateZ);
           if nanoScope.LithoIsFeedbackOn()
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is on');    
           else
                set(afmGUI.indicatorFeedbackOnOff,'String','Feedback is off');
           end
       end
       
       function DisableGui(obj, aGUI)
            %Runs whenever a measurement is started. Disables all controls that
            %could affect the performance of the sweep.
            set(aGUI.ampChan1, 'Enable', 'off');
            set(aGUI.ampChan2, 'Enable', 'off');
            set(aGUI.freqCenterResonance, 'Enable', 'off');
            set(aGUI.freqDetuning1, 'Enable', 'off');
            set(aGUI.freqDetuning2, 'Enable', 'off');
            
            set(aGUI.piTime, 'Enable', 'off');
            set(aGUI.depopulationTime, 'Enable', 'off');
            set(aGUI.preReadoutWait, 'Enable', 'off');
            set(aGUI.sampleWidth, 'Enable', 'off');
            set(aGUI.readoutTime, 'Enable', 'off');
            set(aGUI.initTime, 'Enable', 'off');
            set(aGUI.delayTimeAOM, 'Enable', 'off');
            set(aGUI.numReadBuffers, 'Enable', 'off');
            set(aGUI.buttonBrowseSequences, 'Enable', 'off');
            set(aGUI.pulseFile, 'Enable', 'off');
            set(aGUI.checkbox50nsSignalAOM_APD, 'Enable', 'off');
            set(aGUI.checkbox50nsReferenceAOM_APD, 'Enable', 'off');
            
            set(aGUI.tipLiftHeight_nm, 'Enable','off');
            set(aGUI.scanSizePerDim, 'Enable','off');
            set(aGUI.numPixelsPerDim, 'Enable','off');
            set(aGUI.numRepsPerPixel, 'Enable','off');
            set(aGUI.numPlotAverages, 'Enable','off');
            set(aGUI.checkboxLaserFollows, 'Enable','off');
            
            set(aGUI.buttonStartGradientScan, 'Enable','off');
            
            set(aGUI.buttonLithoBegin, 'Enable','off');
            set(aGUI.buttonStopLithoScan, 'Enable','off');
            set(aGUI.buttonStartLithoScan, 'Enable','off');
            set(aGUI.buttonCenterXY, 'Enable','off');
            set(aGUI.buttonMoveScannerpX, 'Enable','off');
            set(aGUI.buttonMoveScannerpY, 'Enable','off');
            set(aGUI.buttonMoveScannernX, 'Enable','off');
            set(aGUI.buttonMoveScannernY, 'Enable','off');
            set(aGUI.scannerOffsetX_nm, 'Enable','off');
            set(aGUI.scannerOffsetY_nm, 'Enable','off');
            set(aGUI.buttonSetOffsetFromEdit, 'Enable','off');
            
            set(aGUI.scanAngle_deg, 'Enable','off');
            %set(aGUI.panelMeasurementType,'Enable','off');
       end
       
       function EnableGui(obj, aGUI)
            %Runs whenever a measurement is ended. Re-enables controls
            set(aGUI.ampChan1, 'Enable', 'on');
            set(aGUI.ampChan2, 'Enable', 'on');
            set(aGUI.freqCenterResonance, 'Enable', 'on');
            set(aGUI.freqDetuning1, 'Enable', 'on');
            set(aGUI.freqDetuning2, 'Enable', 'on');
            
            set(aGUI.piTime, 'Enable', 'on');
            set(aGUI.depopulationTime, 'Enable', 'on');
            set(aGUI.preReadoutWait, 'Enable', 'on');
            set(aGUI.sampleWidth, 'Enable', 'on');
            set(aGUI.readoutTime, 'Enable', 'on');
            set(aGUI.initTime, 'Enable', 'on');
            set(aGUI.delayTimeAOM, 'Enable', 'on');
            set(aGUI.numReadBuffers, 'Enable', 'on');
            set(aGUI.buttonBrowseSequences, 'Enable', 'on');
            set(aGUI.pulseFile, 'Enable', 'on');
            set(aGUI.checkbox50nsSignalAOM_APD, 'Enable', 'on');
            set(aGUI.checkbox50nsReferenceAOM_APD, 'Enable', 'on');
            
            set(aGUI.tipLiftHeight_nm, 'Enable','on');
            set(aGUI.scanSizePerDim, 'Enable','on');
            set(aGUI.numPixelsPerDim, 'Enable','on');
            set(aGUI.numRepsPerPixel, 'Enable','on');
            set(aGUI.numPlotAverages, 'Enable','on');
            set(aGUI.checkboxLaserFollows, 'Enable','on');
            
            set(aGUI.buttonStartGradientScan, 'Enable','on');
            
            set(aGUI.buttonLithoBegin, 'Enable','on');
            set(aGUI.buttonStopLithoScan, 'Enable','on');
            set(aGUI.buttonStartLithoScan, 'Enable','on');
            set(aGUI.buttonCenterXY, 'Enable','on');
            set(aGUI.buttonMoveScannerpX, 'Enable','on');
            set(aGUI.buttonMoveScannerpY, 'Enable','on');
            set(aGUI.buttonMoveScannernX, 'Enable','on');
            set(aGUI.buttonMoveScannernY, 'Enable','on');
            set(aGUI.scannerOffsetX_nm, 'Enable','on');
            set(aGUI.scannerOffsetY_nm, 'Enable','on');
            set(aGUI.buttonSetOffsetFromEdit, 'Enable','on');
            
            set(aGUI.scanAngle_deg, 'Enable','on');
            %set(aGUI.panelMeasurementType,'Enable','on');
       end
       
   end
   
end