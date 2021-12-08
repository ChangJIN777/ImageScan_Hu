classdef MagnetScanningTools <handle
    % Controls the magnet scanning function
    
    properties
        hImage;
        imageScanHandles;
        DAQ;
        DAQManager;
        pulseBlaster;
        srs;
        NSamples = 2;
        
        pTime;
        uTime;
        wTime;
        sTime;
        rTime;
        iTime;    
        aTime;
        qTime;
        totalSequence; % property to avoid return value of SetupStaticPulseSequence()
        pulseReps;
        numBuffers;
        counterData;
        currentNSamples;
        bUsePulseSequence;
    end
    
    methods
        
        function obj=MagnetScanningTools(imageScanHandles)
            obj.imageScanHandles = imageScanHandles;
            obj.DAQManager = obj.imageScanHandles.DAQManager;
            obj.DAQ = obj.DAQManager.DAQ;
            obj.pulseBlaster = obj.imageScanHandles.PulseInterpreter;
            obj.srs = obj.imageScanHandles.srs;
        end   
        
        function setNTypeOn(obj)
           fopen(obj.srs);
            fprintf(obj.srs, ['ENBL ', '0']);
            fprintf(obj.srs, ['ENBR ', '1']);
            fclose(obj.srs);  
        end
        function setNTypeOff(obj)
            fopen(obj.srs);
            fprintf(obj.srs, ['ENBR ', '0']); % turn off the N RF output
            fclose(obj.srs);
        end
        function setAmp(obj, ampl)
            %Sets the RF amplitude manually to the passed in value
            fopen(obj.srs);
            %fprintf(obj.srs, ['AMPL ', num2str(obj.amplitude)]); % bnc
            fprintf(obj.srs, ['AMPR ', num2str(ampl)]); % Ntype
            fclose(obj.srs);
        end
        function setFreq(obj, centerFreq, detuning1)
            %Sets the frequency manually to the passed in value
            fopen(obj.srs);
            fprintf(obj.srs,['FREQ ', num2str(centerFreq+detuning1),' MHz']); % write to the SG384
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
       
        function SetupStaticPulseSequence(obj,handles)
            % "handles" will be used later to grab pulse sequence values
            % and sequence .esr file from the GUI
            % set up the pulse sequence. There is no tau to sweep so all the
              % steps are done outside the main measurement loop
              
              % get the pulse parameter values form the GUI, simple naming
            obj.pTime =50000;%= str2double(get(afmGUI.piTime,'String'));
            obj.uTime =500;%= str2double(get(afmGUI.depopulationTime,'String'));
            obj.wTime =500;%= str2double(get(afmGUI.preReadoutWait,'String'));
            obj.sTime =50;%= str2double(get(afmGUI.sampleWidth,'String'));
            obj.rTime =48950;%= str2double(get(afmGUI.readoutTime,'String'));
            obj.iTime =3000;%= str2double(get(afmGUI.initTime,'String'));    
            obj.aTime =860;%= str2double(get(afmGUI.delayTimeAOM,'String'));
            obj.qTime=0; % space reserved for IQ time if needed later
              
              INST_LONG_DELAY = 7;
              INST_CONTINUE = 0;
              INST_BRANCH = 6;
              INST_STOP = 1;
              MINPULSE = 10; % nanoseconds
              %esrStruct = tdfread(get(afmGUI.pulseFile, 'String'));
              %esrStruct = tdfread([obj.imageScanHandles.configS.sequenceFolder 'inUse_sequences\AFMsequenceCWLaser_1RF_1channel_wAfterRF.esr']);
              esrStruct = tdfread('C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\AFMsequenceCWLaser_1RF_1channel_wAfterRF.esr');
              [numBits, tempSize] = size(fieldnames(esrStruct)); % counts number of struct fields 'bit1' 'bit2', etc...
              pulseStr = cell(numBits, 1);
              pulseNum = cell(numBits, 1);
              numInstructions = zeros(1,numBits);

              for nb = 1:numBits
                tempCell = obj.pulseBlaster.loadESRPulse(eval(['esrStruct.bit' num2str(nb)]));

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
                      
                      % on coffeeside, flip bit AOM
                      if mb == 1
                           if tempCell{1,2}(k) == 0
                               pulseNum{mb}(k,2) = 14680065;
                           elseif tempCell{1,2}(k) == 14680065
                               pulseNum{mb}(k,2) = 0;
                           end
                      else
                           pulseNum{mb}(k,2) = tempCell{1,2}(k);
                      end
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

           % fprintf('%e\t%e\t%e\t%e\t%e\n',obj.totalSequence'); %print debug
            
            % the return is obj.totalSequence
        end
        
        function MagnetScanFnct(obj,handles)
            % Function to scan magnet with thorlabs APT while tracking PL
            
            % Enable scanning mode
            global scanning 
            scanning = 1;
            global state
            
            obj.DAQ.ClearTask('CountPhotons');
            obj.DAQ.ClearTask('ClockPeriod');
            
            % First, check scan ranges, if then account for scan modes
            if handles.scanmode == 1 || handles.scanmode == 2 || handles.scanmode == 3 %(Always)
                scanmaxX = handles.range+handles.scancenter(1);
                scanminX = -1*handles.range+handles.scancenter(1);
            else
                scanmaxX = handles.scancenter(1);
                scanminX = handles.scancenter(1);
            end
            if handles.scanmode == 1 || handles.scanmode == 3
                scanmaxY = handles.range+handles.scancenter(2);
                scanminY = -1*handles.range+handles.scancenter(2);
            else
                scanmaxY = handles.scancenter(2);
                scanminY = handles.scancenter(2);
            end
            if handles.scanmode == 2 || handles.scanmode == 3
                scanmaxZ = handles.range+handles.scancenter(3);
                scanminZ = -1*handles.range+handles.scancenter(3);
            else
                scanmaxZ = handles.scancenter(3);
                scanminZ = handles.scancenter(3);
            end

            allparamsOK = scanmaxX<=handles.scanbounds(1) && scanminX>=0&&...
                scanmaxY<=handles.scanbounds(2) && scanminY>=0&&...
                scanmaxZ<=handles.scanbounds(3) && scanminZ>=0&&...
                handles.points>=5 && handles.points<=200;

            if allparamsOK
                disp('SCAN PROCEEDING')
            else
                disp('Error: scanning parameters out of range')
                scanning = 0;
                state = 0;
                return
            end
            
            if scanning == 0
                disp('SCAN STOPPED')
                return
            end
            
            obj.bUsePulseSequence = get(handles.checkbox_doPulseSequence,'Value'); % get from from the GUI checkbox
            obj.pulseReps =str2double(get(handles.editPulseReps,'String')); % get from the GUI edit or compute from a dwell time
            obj.numBuffers = 4; % get
            obj.currentNSamples = obj.numBuffers*obj.pulseReps + 1;
            if obj.bUsePulseSequence
                rfAmplitude = -7;%str2double(get(handles.editAmplitude));
                centerFreq = 1470;%str2double(get(handles.editCenterFreq));
                detuning = 0;%str2double(get(handles.detuning));
                % SRS settings
                obj.setNTypeOn();
                obj.setAmp(rfAmplitude); %Set the amplitude
                obj.setFreq(centerFreq, detuning);
            end
            %%% Copied in code
            if handles.scanmode == 1

                % Set up scan dimensions and preallocate a matrix for data
                
                pts = round(handles.points);
                xposvector = linspace(scanminX,scanmaxX,pts);
                yposvector = linspace(scanminY,scanmaxY,pts);
                zpos = handles.scancenter(3);
                Positiondatamatrix = zeros(pts,pts,3);
                PLdatamatrix = zeros(pts,pts); % for PL-only scan type, or microwaves off state or other pulse sequence chan 1
                PLdatamatrix2 = zeros(pts,pts); % for microwaves on state or other pulse sequence chan 2

                % Move to first position
                % Pick most negative corner -- farthest from sample

                handles.APThandleX.SetAbsMovePos(0,xposvector(1));
                handles.APThandleY.SetAbsMovePos(0,yposvector(1));
                handles.APThandleZ.SetAbsMovePos(0,zpos);

                handles.APThandleX.MoveAbsolute(0,1==0);
                handles.APThandleY.MoveAbsolute(0,1==0);
                handles.APThandleZ.MoveAbsolute(0,1==0);

                % WAIT FOR POSITIONING
                
                CheckMoving(handles);

                % Confirm that we have come to the right place
                %   Check to 10 um

                currentXpos = handles.APThandleX.GetPosition_Position(0);
                currentYpos = handles.APThandleY.GetPosition_Position(0);
                currentZpos = handles.APThandleZ.GetPosition_Position(0);

                if abs(currentXpos-xposvector(1))<10^-2
                    disp('x axis ready for scan')
                else
                    disp('Scan initialization failure - X')
                    scanning = 0;
                    state = 0;
                    return
                end
                if abs(currentYpos-yposvector(1))<10^-2
                    disp('y axis ready for scan')
                else
                    disp('Scan initialization failure -Y')
                    scanning = 0;
                    state = 0;
                    return
                end
                if abs(currentZpos-zpos)<10^-2
                    disp('z axis ready for scan')
                else
                    disp('Scan initialization failure - Z')
                    scanning = 0;
                    state = 0;
                    return
                end

                trackcount = 0;
                
                % Set jog distances for X and Y, if using jog moves

                %xjogdistance = xposvector(3)-xposvector(2);
                %yjogdistance = yposvector(3)-yposvector(2);
                %handles.APThandleX.SetJogStepSize(0,xjogdistance);
                %handles.APThandleY.SetJogStepSize(0,yjogdistance);

                % Scan

                for i = 1:pts
                    
                    for j = 1:pts
                    
                        % Check if scan is stopped
                        if scanning == 0
                            disp('SCAN STOPPED')
                            handles.MagnetScanningTools.AutoSave(handles, PLdatamatrix, PLdatamatrix2, Positiondatamatrix)
                            obj.DAQ.ClearTask('CountPhotons');
                            obj.DAQ.ClearTask('ClockPeriod');
                            return
                        end
                        
                        % Jog if not at j=1; always Absolute Move
                        %if j ~= 1
                            %handles.APThandleY.MoveJog(0,1);
                                handles.APThandleY.SetAbsMovePos(0,yposvector(j));
                                handles.APThandleY.MoveAbsolute(0,1==0);
                            % Wait for Positioning to complete
                                CheckMoving(handles);
                        %end     

                        % Record PL and Position Data
                        if obj.bUsePulseSequence
                            [PLdatamatrix2(i,j), PLdatamatrix(i,j)] = obj.PerformSequence(handles);
                        else
                            PLdatamatrix(i,j) = obj.readPL(handles);
                        end
                        Positiondatamatrix(i,j,1) = handles.APThandleX.GetPosition_Position(0);
                        Positiondatamatrix(i,j,2) = handles.APThandleY.GetPosition_Position(0);
                        Positiondatamatrix(i,j,3) = handles.APThandleZ.GetPosition_Position(0);
                        
                        trackcount = trackcount + 1;
                        if (handles.tracken == 1) && (trackcount - handles.tracknum == 0)
                            disp('tracking')
                            % track
                            obj.pulseBlaster.stopPulse();
                            if obj.imageScanHandles.configS.bHaveInverterBoard==1%get(esrGUI.checkboxAOMInverter,'Value')==1
                                %
                            else
                                obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
                                obj.pulseBlaster.loadToPulseblaster();
                                obj.pulseBlaster.runPulse();
                            end
                            
                            obj.imageScanHandles.StateControl.changeToTrackingState(obj.imageScanHandles, true);
                            obj.pulseBlaster.stopPulse();
                            % reset counter
                            trackcount = 0;
                        end
                        
                    end

                    % Go to next line: absolute move to make sure errors don't accumulate
                    if i~=pts
                        handles.APThandleX.SetAbsMovePos(0,xposvector(i+1));
                        handles.APThandleY.SetAbsMovePos(0,yposvector(1));
                        handles.APThandleZ.SetAbsMovePos(0,zpos);

                        handles.APThandleX.MoveAbsolute(0,1==0);
                        handles.APThandleY.MoveAbsolute(0,1==0);
                        handles.APThandleZ.MoveAbsolute(0,1==0);
                    end

                    % Wait for positioning
                    CheckMoving(handles);
                
                    % Plot partial image    
                    dims = [scanminX,scanmaxX,scanminY,scanmaxY];
                    obj.updateImage(handles,PLdatamatrix',PLdatamatrix2',dims);
                end


            elseif handles.scanmode == 2
                
                % Set up scan dimensions and preallocate a matrix for data
                
                pts = round(handles.points);
                xposvector = linspace(scanminX,scanmaxX,pts);
                zposvector = linspace(scanminZ,scanmaxZ,pts);
                ypos = handles.scancenter(2);
                Positiondatamatrix = zeros(pts,pts,3);
                PLdatamatrix = zeros(pts,pts);
                PLdatamatrix2 = zeros(pts,pts); % for microwaves on state or other pulse sequence chan 2

                % Move to first position
                % Pick most negative corner -- farthest from sample

                handles.APThandleX.SetAbsMovePos(0,xposvector(1));
                handles.APThandleY.SetAbsMovePos(0,ypos);
                handles.APThandleZ.SetAbsMovePos(0,zposvector(1));

                handles.APThandleX.MoveAbsolute(0,1==0);
                handles.APThandleY.MoveAbsolute(0,1==0);
                handles.APThandleZ.MoveAbsolute(0,1==0);

                % WAIT FOR POSITIONING
                
                CheckMoving(handles);

                % Confirm that we have come to the right place
                %   Check to 10 um

                currentXpos = handles.APThandleX.GetPosition_Position(0);
                currentYpos = handles.APThandleY.GetPosition_Position(0);
                currentZpos = handles.APThandleZ.GetPosition_Position(0);

                if abs(currentXpos-xposvector(1))<10^-2
                    disp('x axis ready for scan')
                else
                    disp('Scan initialization failure - X')
                    scanning = 0;
                    state = 0;
                    return
                end
                if abs(currentYpos-ypos(1))<10^-2
                    disp('y axis ready for scan')
                else
                    disp('Scan initialization failure -Y')
                    scanning = 0;
                    state = 0;
                    return
                end
                if abs(currentZpos-zposvector(1))<10^-2
                    disp('z axis ready for scan')
                else
                    disp('Scan initialization failure - Z')
                    scanning = 0;
                    state = 0;
                    return
                end

                trackcount=0;
                
                % Set jog distances for X and Z, if using jog moves

                %xjogdistance = xposvector(3)-xposvector(2);
                %zjogdistance = zposvector(3)-zposvector(2);
                %handles.APThandleX.SetJogStepSize(0,xjogdistance);
                %handles.APThandleZ.SetJogStepSize(0,zjogdistance);

                % Scan
                for avgnum = 1:100
                for i = 1:pts
                    
                    for j = 1:pts
                    
                        % Check if scan is stopped
                        if scanning == 0
                            disp('SCAN STOPPED')
                            handles.MagnetScanningTools.AutoSave(handles, PLdatamatrix,PLdatamatrix2, Positiondatamatrix)
                            obj.DAQ.ClearTask('CountPhotons');
                            obj.DAQ.ClearTask('ClockPeriod');
                            return
                        end
                        
                        % Jog or Absolute Move if not at j=1
                        if j ~= 1
                            %handles.APThandleY.MoveJog(0,1);
                                handles.APThandleX.SetAbsMovePos(0,xposvector(j));
                                handles.APThandleX.MoveAbsolute(0,1==0);
                            % Wait for Positioning to complete
                                CheckMoving(handles);
                        end

                        % Record PL and Position Data
                        if obj.bUsePulseSequence
                            [PLdatamatrix2(i,j), PLdatamatrix(i,j)] = obj.PerformSequence(handles);
                        else
                            PLdatamatrix(i,j) = obj.readPL(handles);
                        end
                        Positiondatamatrix(i,j,1) = handles.APThandleX.GetPosition_Position(0);
                        Positiondatamatrix(i,j,2) = handles.APThandleY.GetPosition_Position(0);
                        Positiondatamatrix(i,j,3) = handles.APThandleZ.GetPosition_Position(0);

                        trackcount = trackcount + 1;
                        if (handles.tracken == 1) && (trackcount - handles.tracknum == 0)
                            disp('tracking')
                            % track
    %                        obj.pulseBlaster.stopPulse();
    %                        if obj.imageScanHandles.configS.bHaveInverterBoard==1%get(esrGUI.checkboxAOMInverter,'Value')==1
                                %
    %                        else
    %                            obj.pulseBlaster.setCurrentPulse([obj.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
    %                            obj.pulseBlaster.loadToPulseblaster();
    %                            obj.pulseBlaster.runPulse();
    %                        end
                            
                            obj.imageScanHandles.StateControl.changeToTrackingState(obj.imageScanHandles, true);
    %                        obj.pulseBlaster.stopPulse();
                            % reset counter
                            trackcount = 0;
                        end

                    end

                    % Go to next line: absolute move to make sure errors don't accumulate
                    if i~=pts
                        handles.APThandleX.SetAbsMovePos(0,xposvector(1));
                        handles.APThandleY.SetAbsMovePos(0,ypos);
                        handles.APThandleZ.SetAbsMovePos(0,zposvector(i+1));

                        handles.APThandleX.MoveAbsolute(0,1==0);
                        handles.APThandleY.MoveAbsolute(0,1==0);
                        handles.APThandleZ.MoveAbsolute(0,1==0);
                    end

                    % Wait for positioning
                    CheckMoving(handles);
                    
                    % Plot partial image
                    dims = [scanminX,scanmaxX,scanminZ,scanmaxZ];
                    obj.updateImage(handles,PLdatamatrix,PLdatamatrix2,dims)
                end
                %need to remove avg num XXXXX 
                                    % XXX Average Scans. This must be commented out when
                    % doing MRI!!!!!
                    % Use PLdatamatrix2 as average
                    PLdatamatrix2 = PLdatamatrix2 + (PLdatamatrix-PLdatamatrix2)/avgnum;
                handles.MagnetScanningTools.AutoSave(handles, PLdatamatrix,PLdatamatrix2, Positiondatamatrix,avgnum)
                end

            elseif handles.scanmode == 3
                disp('Future implementation')% XXX
                return
            else
                disp('Invalid ScanMode')
                return
            end

            % Return to ScanCenter
            
                handles.APThandleX.SetAbsMovePos(0,handles.scancenter(1));
                handles.APThandleY.SetAbsMovePos(0,handles.scancenter(2));
                handles.APThandleZ.SetAbsMovePos(0,handles.scancenter(3));

                handles.APThandleX.MoveAbsolute(0,1==0);
                handles.APThandleY.MoveAbsolute(0,1==0);
                handles.APThandleZ.MoveAbsolute(0,1==0);

            % Wait for completion of positioning
                CheckMoving(handles);
            
            disp('SCAN ENDING')
            
            % Call plotting function for the final image
            dims = [scanminX,scanmaxX,scanminZ,scanmaxZ];
            obj.updateImage(handles,PLdatamatrix,PLdatamatrix2,dims);
                
            % Call AutoSave function
            handles.MagnetScanningTools.AutoSave(handles, PLdatamatrix,PLdatamatrix2, Positiondatamatrix,1000)
            
            if obj.bUsePulseSequence
                % turn off rf and pulse operations
                obj.setNTypeOff();
                obj.pulseBlaster.stopPulse();
            end
            scanning = 0;
            state = 0;
        end
        
        function AutoSave(obj,handles, plData, plData2, posData,avgnum)
            
            % Tick file number
            
            myFormattedFileNum = get(handles.editAutosaveNumber,'String');
            filenum = str2double(myFormattedFileNum);
            %filenum = filenum+1; XXXXXXXXXXXXXXXXXXXXXXX
            filenum = sprintf('%04d',filenum);
            set(handles.editAutosaveNumber,'String',filenum);
            
            % Set up file
            
            myFormattedPathname = get(handles.editFilePath,'String');
            myFormattedFilePrefix = get(handles.editAutosaveString,'String');
            myFormattedFileNum = get(handles.editAutosaveNumber,'String');
            fileName = [myFormattedFilePrefix myFormattedFileNum '_' num2str(avgnum) '.txt'];
            if exist(myFormattedPathname,'dir') == 0 %path does not exist?
                mkdir(myFormattedPathname); %make folder
            end
            
            %XXX Meta Data
            
            % Writefile
            
            file = [myFormattedPathname fileName];
            fid = fopen(file,'wt');
            %fprintf(fid, metadata)
            fprintf(fid, '\n\n');
            fprintf(fid, 'PL DATA');
            fprintf(fid, '\n\n');
            fclose(fid);
            dlmwrite(file, plData,'-append','delimiter','\t');
            fid = fopen(file,'a');
            fprintf(fid, '\n\n');
            fprintf(fid, 'PL DATA II [WITH MICROWAVES]');
            fprintf(fid, '\n\n');
            fclose(fid);
            dlmwrite(file, plData2,'-append','delimiter','\t');
            fid = fopen(file,'a');
            fprintf(fid, '\r\n\n');
            fprintf(fid, 'X POSITION DATA');
            fprintf(fid, '\n\n');
            fclose(fid);
            dlmwrite(file, posData(:,:,1),'-append','delimiter','\t');
            fid = fopen(file,'a');
            fprintf(fid, '\n\n');
            fprintf(fid, 'Y POSITION DATA');
            fprintf(fid, '\n\n');
            fclose(fid);
            dlmwrite(file, posData(:,:,2),'-append','delimiter','\t');
            fid = fopen(file,'a');
            fprintf(fid, '\n\n');
            fprintf(fid, 'Z POSITION DATA');
            fprintf(fid, '\n\n');
            fclose(fid);
            dlmwrite(file, posData(:,:,3),'-append','delimiter','\t');
            % Note: open with excel for proper formatting
            
            disp(['FILE SAVED AS: ' fileName])
            
            
        end
        
        function updateImage(obj,handles,plData,plData2,dims)
            if obj.bUsePulseSequence  
                % show channel 1 or 2 based on radio button
                if get(handles.radio_plotChannel1,'Value')
                    obj.hImage = imagesc(dims(1:2),dims(3:4),plData,'Parent',handles.axesMagnet);
                elseif get(handles.radio_plotChannel2,'Value')
                    obj.hImage = imagesc(dims(1:2),dims(3:4),plData2,'Parent',handles.axesMagnet);
                elseif get(handles.radio_plotChannel3,'Value')
                    obj.hImage = imagesc(dims(1:2),dims(3:4),plData2-plData,'Parent',handles.axesMagnet);
                end
            else
                % always show channel1
                obj.hImage = imagesc(dims(1:2),dims(3:4),plData,'Parent',handles.axesMagnet);
            end
            set(handles.axesMagnet, 'YDir','normal');
            colorbar('peer', handles.axesMagnet);
            caxis(handles.axesMagnet,'auto');
            % fix axes
            if handles.scanmode == 1
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Y (mm)')
            elseif handles.scanmode == 2
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Z (mm)')
            end
        end
        
        function [sPoint rPoint] = SortCounterBuffers(obj,handles)
           % based on 1) how many counter buffers per pulse Rep (usually 2 or 4)
           % 2) whether to turn on APD count early by 50ns, checkboxes
           
            check50Sig = false;%get(afmGUI.checkbox50nsSignalAOM_APD,'Value'); 
            check50Ref = false;%get(afmGUI.checkbox50nsReferenceAOM_APD,'Value');
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
        
        function [signalPoint refPoint] = PerformSequence(obj,handles)
            
            global scanning
            
            SetupStaticPulseSequence(obj,handles);
            
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

            while (obj.DAQ.IsTaskDone('Counter') == false && scanning)
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

            obj.counterData = diff(obj.counterData);

            % put the new counts into kCounts/s, dividing by the
            % correct readout time in obj.SortCounterBuffers()
            [signalPoint, refPoint] = obj.SortCounterBuffers(handles);
            
            obj.pulseBlaster.stopPulse();
            obj.DAQ.StopTask('Counter');
            obj.DAQ.ClearTask('Counter');
        end
        
        function measuredPL = readPL(obj,handles)
            
            count = [];
            perPointDwell = handles.dwelltime;
            dutyCycle = 0.5;
            
            obj.DAQ.ClearTask('CountPhotons');
            obj.DAQ.ClearTask('ClockPeriod');
            
            obj.DAQ.CreateTask('ClockPeriod');
            clockFrequency = 1/perPointDwell;
            clockLine = 1;
            obj.DAQ.ConfigureClockOut('ClockPeriod', clockLine,clockFrequency,dutyCycle);
            
            obj.DAQ.CreateTask('CountPhotons');
            counterLine = 1;
            obj.DAQ.ConfigureCounterIn('CountPhotons',counterLine,obj.NSamples);
            obj.DAQ.StartTask('ClockPeriod');
            obj.DAQ.StartTask('CountPhotons');
            while obj.DAQ.IsTaskDone('CountPhotons')==false
                pause(0.001)
            end
            NSamplesAvailable = obj.DAQ.GetAvailableSamples('CountPhotons');
            if NSamplesAvailable > 0 
                % collects specified number obj.NSamples=2
                count = [count ...
                    double(obj.DAQ.ReadCounterBuffer('CountPhotons',NSamplesAvailable))];
            end
            
            obj.DAQ.StopTask('CountPhotons');
            obj.DAQ.StopTask('ClockPeriod');
            
            obj.DAQ.ClearTask('CountPhotons');
            obj.DAQ.ClearTask('ClockPeriod');
            
            measuredPL = ( count(2) - count(1) )/(1000*perPointDwell);
        end
    end
end